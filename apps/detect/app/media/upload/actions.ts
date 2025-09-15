"use server"

import { headers } from "next/headers"

import { db, getRoleByUserId, getServerRole } from "../../server"
import { checkIsThrottled } from "../../throttle/actions"
import { buildFakeMediaUrl } from "./util"
import { getMediaResClient } from "../../services/mediares"
import { maybeAttributeWithOrg, checkCreateQuery, recordMediaUserType } from "../../api/resolve-media/resolve"
import { UserType } from "@prisma/client"
import { isUserInOrg } from "../../utils/clerk"
import { currentUser } from '@clerk/nextjs/server';


export type SaveRequest = {
  id: string
  mimeType: string
  filename: string
  userId?: string
  orgId?: string | undefined
}

export type SaveResponse =
  | {
      type: "saved"
      mediaUrl: string
    }
  | { type: "error"; message: string }

function resuffix(id: string, suff: string) {
  const dotidx = id.lastIndexOf(".")
  return dotidx > 0 ? `${id.substring(0, dotidx)}${suff}` : `${id}${suff}`
}

// userId allows API users to call this function.
export async function saveUploadedFile({ id, mimeType, filename, userId, orgId }: SaveRequest): Promise<SaveResponse> {
  // TODO: I'm pretty sure this line let's anyone (including anonymous people) spoof as any user. That's probably bad...

  const user = await currentUser();
  // const role = await (user.id ? getRoleByUserId(user.id) : getServerRole())
  // if (!role.user) return { type: "error", message: "Must be logged in." }
  if (!user) return { type: "error", message: "Must be logged in." }

  const role = await getRoleByUserId(user.id)

	console.warn("saveUploadedFile checkpoint 1");
  if (orgId && !(await isUserInOrg(orgId))) {
    const message = `Unauthorized access. User is not a member of org. [userId=${role.id}, orgId=${orgId}]`
    console.warn(message)
    return { type: "error", message }
  }
	console.warn("saveUploadedFile checkpoint 2");

  // check if we're throttled, we're repeating this check here because the earlier one in the flow
  // is client-side and could be circumvented by a motivated actor
  const isThrottled = await checkIsThrottled(userId, UserType.REGISTERED)
	console.warn("saveUploadedFile checkpoint 3");
  if (isThrottled) {
    console.warn(`Throttling request for media upload [id=${id}]`)
    return { type: "error", message: "Too many requests in the last hour, please try again later." }
  }
	console.warn("saveUploadedFile checkpoint 4");

  // squireling the filename away here for later use in this fake url
  const pseudoUrl = buildFakeMediaUrl(id, filename)
	console.warn("saveUploadedFile checkpoint 5");

  // finalize the url in mediares (handles things like thumbnails)
  const result = await getMediaResClient().finalizeFileUpload({ mediaId: id, mimeType })
	console.warn("saveUploadedFile checkpoint 6");
  if (result.result == "failure") {
    console.warn(`Failed to finalize mediares url [id=${id}, mediaUrl=${pseudoUrl}]`, result)
    return { type: "error", message: result.reason }
  }
	console.warn("saveUploadedFile checkpoint 7");

  // if this is a video, the audio will be extracted as an MP3 and saved with its same media id but with the suffix
  // changed to mp3, so include that in its definition
  const isVideo = mimeType.startsWith("video/")
  const audioId = isVideo ? resuffix(id, ".mp3") : null
  const audioMimeType = isVideo ? "audio/mp3" : null
	console.warn("saveUploadedFile checkpoint 8");

  // save records for the media associated with this post
  try {
    await db.media.create({
      data: {
        id,
        mediaUrl: pseudoUrl,
        mimeType,
        audioId,
        audioMimeType,
        external: !role.friend,
        apiKeyId: null,
      },
    })
	console.warn("saveUploadedFile checkpoint 9");
    await recordMediaUserType(id, UserType.REGISTERED, userId)
  } catch (e) {
    console.warn(`Failed to create postMedia record for file upload [mediaId=${id}]`, e)
  }

	console.warn("saveUploadedFile checkpoint A");
  let postMedia
  try {
    postMedia = await db.postMedia.create({
      data: { postUrl: pseudoUrl, mediaId: id },
      include: { media: { include: { meta: true } } },
    })
  } catch (e) {
    console.warn(`Failed to create postMedia records [mediaId=${id}]`, e)
  }

	console.warn("saveUploadedFile checkpoint B");
  try {
    const source = `user:${role.email}`
    await db.mediaMetadata.create({ data: { mediaId: id, source } })
    if (postMedia) {
      await maybeAttributeWithOrg({ media: postMedia.media, orgId })
    }
  } catch (e) {
    console.warn(`Failed to create postMedia records [mediaId=${id}]`, e)
  }

	console.warn("saveUploadedFile checkpoint C");
  const ipAddr = headers().get("x-forwarded-for") ?? ""
	console.warn("saveUploadedFile checkpoint D");
  await checkCreateQuery({ userId: user.id, postUrl: pseudoUrl, ipAddr, orgId, apiAuthInfo: null })
	console.warn("saveUploadedFile checkpoint E");

  return { type: "saved", mediaUrl: pseudoUrl }
}
