-- CreateEnum
CREATE TYPE "UserType" AS ENUM ('ANONYMOUS', 'REGISTERED', 'API');

-- CreateEnum
CREATE TYPE "Trulean" AS ENUM ('UNREVIEWED', 'UNKNOWN', 'FALSE', 'TRUE');

-- CreateEnum
CREATE TYPE "YesNoReview" AS ENUM ('YES', 'NO', 'UNREVIEWED');

-- CreateEnum
CREATE TYPE "RequestState" AS ENUM ('ERROR', 'UPLOADING', 'PROCESSING', 'COMPLETE');

-- CreateEnum
CREATE TYPE "Notability" AS ENUM ('NOTABLE', 'CANDIDATE', 'WAS_NOTABLE', 'PLAIN');

-- CreateEnum
CREATE TYPE "MediaPublisher" AS ENUM ('UNKNOWN', 'OTHER', 'X', 'TIKTOK', 'MASTODON', 'YOUTUBE', 'REDDIT', 'GOOGLE_DRIVE', 'INSTAGRAM', 'FACEBOOK');

-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('UNKNOWN', 'VIDEO', 'IMAGE', 'AUDIO');

-- CreateEnum
CREATE TYPE "ReplyType" AS ENUM ('PROCESSING', 'FINAL');

-- CreateEnum
CREATE TYPE "QueueMessageStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'FAILED', 'COMPLETED', 'CANCELED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" TEXT,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "queries" (
    "id" TEXT NOT NULL,
    "post_url" TEXT NOT NULL,
    "time" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "org_id" TEXT,
    "api_key_id" TEXT,
    "user_id" TEXT NOT NULL,
    "ip_addr" TEXT NOT NULL DEFAULT '',
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "queries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_metadata" (
    "post_url" TEXT NOT NULL,
    "json" TEXT NOT NULL,

    CONSTRAINT "post_metadata_pkey" PRIMARY KEY ("post_url")
);

-- CreateTable
CREATE TABLE "post_media" (
    "post_url" TEXT NOT NULL,
    "media_id" TEXT NOT NULL,

    CONSTRAINT "post_media_pkey" PRIMARY KEY ("post_url","media_id")
);

-- CreateTable
CREATE TABLE "media" (
    "id" TEXT NOT NULL,
    "media_url" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "duration" INTEGER NOT NULL DEFAULT 0,
    "size" INTEGER NOT NULL DEFAULT 0,
    "resolved_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "audio_id" TEXT,
    "audio_mime_type" TEXT,
    "external" BOOLEAN NOT NULL DEFAULT false,
    "results" JSONB NOT NULL DEFAULT '{}',
    "analysis_time" INTEGER NOT NULL DEFAULT 0,
    "source" "MediaPublisher" NOT NULL DEFAULT 'UNKNOWN',
    "source_user_id" TEXT,
    "source_user_name" TEXT,
    "verified_source" BOOLEAN NOT NULL DEFAULT false,
    "postedToX" BOOLEAN NOT NULL DEFAULT false,
    "trimmed" BOOLEAN NOT NULL DEFAULT false,
    "scheduler_message_id" TEXT,
    "api_key_id" TEXT,

    CONSTRAINT "media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_throttle" (
    "media_id" TEXT NOT NULL,
    "user_type" "UserType" NOT NULL,

    CONSTRAINT "media_throttle_pkey" PRIMARY KEY ("media_id")
);

-- CreateTable
CREATE TABLE "media_metadata" (
    "media_id" TEXT NOT NULL,
    "fake" "Trulean" NOT NULL DEFAULT 'UNREVIEWED',
    "audio_fake" "Trulean" NOT NULL DEFAULT 'UNREVIEWED',
    "relabel_fake" "Trulean" NOT NULL DEFAULT 'UNREVIEWED',
    "relabel_audio_fake" "Trulean" NOT NULL DEFAULT 'UNREVIEWED',
    "language" TEXT NOT NULL DEFAULT '',
    "handle" TEXT NOT NULL DEFAULT '',
    "source" TEXT NOT NULL DEFAULT '',
    "keywords" TEXT NOT NULL DEFAULT '',
    "comments" TEXT NOT NULL DEFAULT '',
    "speakers" TEXT NOT NULL DEFAULT '',
    "misleading" BOOLEAN NOT NULL DEFAULT false,
    "no_photorealistic_faces" BOOLEAN NOT NULL DEFAULT false,
    "fakeReviewer" TEXT NOT NULL DEFAULT '',
    "audioFakeReviewer" TEXT NOT NULL DEFAULT '',
    "relabel_fake_reviewer" TEXT NOT NULL DEFAULT '',
    "relabel_fake_audio_reviewer" TEXT NOT NULL DEFAULT '',
    "video_object_overlay" "YesNoReview" NOT NULL DEFAULT 'UNREVIEWED',
    "video_text_overlay" "YesNoReview" NOT NULL DEFAULT 'UNREVIEWED',
    "video_effects" "YesNoReview" NOT NULL DEFAULT 'UNREVIEWED',

    CONSTRAINT "media_metadata_pkey" PRIMARY KEY ("media_id")
);

-- CreateTable
CREATE TABLE "user_feedback" (
    "user_id" TEXT NOT NULL,
    "media_id" TEXT NOT NULL,
    "fake" "Trulean" NOT NULL DEFAULT 'UNKNOWN',
    "comments" TEXT NOT NULL DEFAULT '',

    CONSTRAINT "user_feedback_pkey" PRIMARY KEY ("user_id","media_id")
);

-- CreateTable
CREATE TABLE "analysis_results" (
    "media_id" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "json" TEXT NOT NULL,
    "user_id" TEXT,
    "created" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed" TIMESTAMP(3),
    "request_id" TEXT,
    "request_state" "RequestState",
    "api_key_id" TEXT,

    CONSTRAINT "analysis_results_pkey" PRIMARY KEY ("media_id","source")
);

-- CreateTable
CREATE TABLE "notable_media" (
    "media_id" TEXT NOT NULL,
    "notability" "Notability" NOT NULL DEFAULT 'PLAIN',
    "created" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "score" INTEGER NOT NULL DEFAULT 0,
    "title" TEXT NOT NULL DEFAULT '',
    "description" TEXT NOT NULL DEFAULT '',
    "appeared_in" "MediaPublisher" NOT NULL DEFAULT 'UNKNOWN',
    "media_type" "MediaType" NOT NULL DEFAULT 'UNKNOWN',
    "image_preview_url" TEXT NOT NULL DEFAULT '',

    CONSTRAINT "notable_media_pkey" PRIMARY KEY ("media_id")
);

-- CreateTable
CREATE TABLE "QuizMedia" (
    "media_id" TEXT NOT NULL,

    CONSTRAINT "QuizMedia_pkey" PRIMARY KEY ("media_id")
);

-- CreateTable
CREATE TABLE "reruns" (
    "id" TEXT NOT NULL,
    "creator_id" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "keywords" TEXT NOT NULL,
    "mediaId" TEXT NOT NULL DEFAULT '',
    "from_date" TEXT,
    "to_date" TEXT,
    "include_unknown" BOOLEAN NOT NULL DEFAULT false,
    "only_errors" BOOLEAN NOT NULL DEFAULT false,
    "leeway_days" INTEGER NOT NULL DEFAULT 0,
    "matched" INTEGER NOT NULL,
    "started" TIMESTAMP(3) NOT NULL,
    "complete" INTEGER NOT NULL,
    "completed" TIMESTAMP(3),

    CONSTRAINT "reruns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rate_limits" (
    "user_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "times" INTEGER[],

    CONSTRAINT "rate_limits_pkey" PRIMARY KEY ("user_id","action")
);

-- CreateTable
CREATE TABLE "mention_queue" (
    "id" TEXT NOT NULL,
    "platform" "MediaPublisher" NOT NULL,
    "platform_id" TEXT NOT NULL,
    "platform_user_name" TEXT,
    "media_id" TEXT,
    "enqueued" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mention_queue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mention_reply" (
    "id" TEXT NOT NULL,
    "mention_id" TEXT NOT NULL,
    "type" "ReplyType" NOT NULL DEFAULT 'FINAL',
    "replied" TIMESTAMP(3) NOT NULL,
    "platform" "MediaPublisher" NOT NULL,
    "platform_id" TEXT NOT NULL,

    CONSTRAINT "mention_reply_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verified_source" (
    "id" TEXT NOT NULL,
    "platform" "MediaPublisher" NOT NULL,
    "display_name" TEXT,
    "platform_id" TEXT NOT NULL,
    "added" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verified_source_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GroundTruthUpdate" (
    "id" TEXT NOT NULL,
    "media_id" TEXT NOT NULL,
    "oldSummary" TEXT NOT NULL,
    "newSummary" TEXT NOT NULL,
    "pollCount" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GroundTruthUpdate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "datasets" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "keywords" TEXT NOT NULL,

    CONSTRAINT "datasets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dataset_groups" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "setIds" TEXT[],
    "from_date" TIMESTAMP(3),
    "to_date" TIMESTAMP(3),

    CONSTRAINT "dataset_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PersistentScratch" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "val" TEXT NOT NULL,

    CONSTRAINT "PersistentScratch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "api_keys" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "user_id" TEXT,
    "org_id" TEXT,
    "created_by_id" TEXT,

    CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "batch_uploads" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "org_id" TEXT,
    "api_key_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "batch_uploads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "batch_upload_items" (
    "id" TEXT NOT NULL,
    "batch_upload_id" TEXT NOT NULL,
    "post_url" TEXT NOT NULL,
    "query_id" TEXT,
    "media_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolve_url_job_id" TEXT,
    "start_analysis_job_id" TEXT,
    "debug_info" JSONB,

    CONSTRAINT "batch_upload_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "queue_messages" (
    "id" TEXT NOT NULL,
    "apikey_id" TEXT,
    "queue_name" TEXT NOT NULL,
    "message" JSONB NOT NULL,
    "priority" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lease_id" TEXT,
    "lease_expiration" TIMESTAMP(3),
    "lease_times" TIMESTAMP(3)[],
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "status" "QueueMessageStatus" NOT NULL DEFAULT 'PENDING',

    CONSTRAINT "queue_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "queries_user_id_idx" ON "queries"("user_id");

-- CreateIndex
CREATE INDEX "media_resolved_at_idx" ON "media"("resolved_at");

-- CreateIndex
CREATE UNIQUE INDEX "mention_queue_platform_platform_id_key" ON "mention_queue"("platform", "platform_id");

-- CreateIndex
CREATE UNIQUE INDEX "mention_reply_mention_id_type_key" ON "mention_reply"("mention_id", "type");

-- CreateIndex
CREATE UNIQUE INDEX "verified_source_platform_platform_id_key" ON "verified_source"("platform", "platform_id");

-- CreateIndex
CREATE UNIQUE INDEX "datasets_name_key" ON "datasets"("name");

-- CreateIndex
CREATE UNIQUE INDEX "dataset_groups_name_key" ON "dataset_groups"("name");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_key_key" ON "api_keys"("key");

-- CreateIndex
CREATE UNIQUE INDEX "api_keys_user_id_org_id_key" ON "api_keys"("user_id", "org_id");

-- AddForeignKey
ALTER TABLE "queries" ADD CONSTRAINT "queries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "queries" ADD CONSTRAINT "queries_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_keys"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_media" ADD CONSTRAINT "post_media_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media" ADD CONSTRAINT "media_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_keys"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_throttle" ADD CONSTRAINT "media_throttle_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_metadata" ADD CONSTRAINT "media_metadata_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_feedback" ADD CONSTRAINT "user_feedback_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_feedback" ADD CONSTRAINT "user_feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "analysis_results" ADD CONSTRAINT "analysis_results_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "analysis_results" ADD CONSTRAINT "analysis_results_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_keys"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notable_media" ADD CONSTRAINT "notable_media_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuizMedia" ADD CONSTRAINT "QuizMedia_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reruns" ADD CONSTRAINT "reruns_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rate_limits" ADD CONSTRAINT "rate_limits_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mention_queue" ADD CONSTRAINT "mention_queue_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mention_reply" ADD CONSTRAINT "mention_reply_mention_id_fkey" FOREIGN KEY ("mention_id") REFERENCES "mention_queue"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroundTruthUpdate" ADD CONSTRAINT "GroundTruthUpdate_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "batch_upload_items" ADD CONSTRAINT "batch_upload_items_query_id_fkey" FOREIGN KEY ("query_id") REFERENCES "queries"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "batch_upload_items" ADD CONSTRAINT "batch_upload_items_batch_upload_id_fkey" FOREIGN KEY ("batch_upload_id") REFERENCES "batch_uploads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "batch_upload_items" ADD CONSTRAINT "batch_upload_items_media_id_fkey" FOREIGN KEY ("media_id") REFERENCES "media"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "queue_messages" ADD CONSTRAINT "queue_messages_apikey_id_fkey" FOREIGN KEY ("apikey_id") REFERENCES "api_keys"("id") ON DELETE SET NULL ON UPDATE CASCADE;
