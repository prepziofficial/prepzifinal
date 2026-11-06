-- CreateTable
CREATE TABLE "Subject" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "paperCode" TEXT,
    "description" TEXT,
    "icon" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Subject_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaperFile" (
    "id" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "paperCode" TEXT,
    "topic" TEXT,
    "kind" TEXT NOT NULL DEFAULT 'TOPICAL',
    "fileName" TEXT,
    "mimeType" TEXT DEFAULT 'application/pdf',
    "size" INTEGER NOT NULL DEFAULT 0,
    "data" BYTEA,
    "externalUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "year" INTEGER,
    "session" TEXT,
    "paperNumber" INTEGER,
    "variant" TEXT,
    "chapterNumber" TEXT,
    "chapterName" TEXT,
    "sectionNumber" TEXT,
    "sectionName" TEXT,

    CONSTRAINT "PaperFile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Setting" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Setting_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "Subject_name_level_key" ON "Subject"("name", "level");

-- CreateIndex
CREATE INDEX "PaperFile_kind_idx" ON "PaperFile"("kind");

-- AddForeignKey
ALTER TABLE "PaperFile" ADD CONSTRAINT "PaperFile_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE CASCADE ON UPDATE CASCADE;
