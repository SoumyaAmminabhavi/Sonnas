-- CreateTable
CREATE TABLE "Post" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT NOT NULL,

    CONSTRAINT "Post_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,
    "refresh_token_expires_in" INTEGER,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "sessionToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "Cake" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "image" TEXT NOT NULL,
    "category" TEXT NOT NULL DEFAULT 'General',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Cake_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CakeOption" (
    "id" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "serves" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
    "cakeId" TEXT NOT NULL,

    CONSTRAINT "CakeOption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppConversation" (
    "id" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "name" TEXT,
    "state" TEXT NOT NULL DEFAULT 'IDLE',
    "selectedCake" TEXT,
    "selectedSize" TEXT,
    "selectedPrice" INTEGER,
    "selectedAddress" TEXT,
    "selectedNotes" TEXT,
    "selectedQuantity" INTEGER DEFAULT 1,
    "customImageUrl" TEXT,
    "selectedDeliveryDate" TEXT,
    "selectedDeliveryTime" TEXT,
    "messages" JSONB DEFAULT '[]',
    "lastMessageAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WhatsAppConversation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppCartItem" (
    "id" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "cakeName" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WhatsAppCartItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppOrder" (
    "id" TEXT NOT NULL,
    "orderNumber" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "customerName" TEXT,
    "totalPrice" INTEGER,
    "address" TEXT,
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "paymentStatus" TEXT NOT NULL DEFAULT 'PENDING',
    "razorpayOrderId" TEXT,
    "paymentId" TEXT,
    "paymentLink" TEXT,
    "isCustom" BOOLEAN NOT NULL DEFAULT false,
    "customImageUrl" TEXT,
    "deliveryDate" TEXT,
    "deliveryTime" TEXT,
    "paymentReminderSent" BOOLEAN NOT NULL DEFAULT false,
    "followUpSent" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WhatsAppOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppSetting" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "WhatsAppSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WhatsAppOrderItem" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "cakeName" TEXT NOT NULL,
    "size" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "WhatsAppOrderItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Post_name_idx" ON "Post"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_sessionToken_key" ON "Session"("sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON "VerificationToken"("identifier", "token");

-- CreateIndex
CREATE UNIQUE INDEX "WhatsAppConversation_phone_key" ON "WhatsAppConversation"("phone");

-- CreateIndex
CREATE INDEX "WhatsAppCartItem_phone_idx" ON "WhatsAppCartItem"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "WhatsAppOrder_orderNumber_key" ON "WhatsAppOrder"("orderNumber");

-- CreateIndex
CREATE INDEX "WhatsAppOrder_phone_idx" ON "WhatsAppOrder"("phone");

-- CreateIndex
CREATE INDEX "WhatsAppOrder_status_idx" ON "WhatsAppOrder"("status");

-- CreateIndex
CREATE INDEX "WhatsAppOrder_createdAt_idx" ON "WhatsAppOrder"("createdAt");

-- CreateIndex
CREATE INDEX "WhatsAppOrder_paymentStatus_idx" ON "WhatsAppOrder"("paymentStatus");

-- CreateIndex
CREATE UNIQUE INDEX "WhatsAppSetting_key_key" ON "WhatsAppSetting"("key");

-- AddForeignKey
ALTER TABLE "Post" ADD CONSTRAINT "Post_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CakeOption" ADD CONSTRAINT "CakeOption_cakeId_fkey" FOREIGN KEY ("cakeId") REFERENCES "Cake"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WhatsAppCartItem" ADD CONSTRAINT "WhatsAppCartItem_phone_fkey" FOREIGN KEY ("phone") REFERENCES "WhatsAppConversation"("phone") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WhatsAppOrder" ADD CONSTRAINT "WhatsAppOrder_phone_fkey" FOREIGN KEY ("phone") REFERENCES "WhatsAppConversation"("phone") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WhatsAppOrderItem" ADD CONSTRAINT "WhatsAppOrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "WhatsAppOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
