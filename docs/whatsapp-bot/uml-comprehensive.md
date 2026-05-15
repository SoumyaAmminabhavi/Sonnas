# Comprehensive UML Documentation for WhatsApp Bot

This document provides a full suite of UML diagrams describing the structural and behavioral aspects of the Sonna's Patisserie WhatsApp Bot.

---

## 1. Class Diagram (Structural)
Defines the core data models and service relationships.

```mermaid
classDiagram
    class WhatsAppConversation {
        +String phone
        +String name
        +ConversationState state
        +String selectedCakeId
        +String selectedSize
        +Int selectedPrice
        +String selectedAddress
        +String selectedNotes
        +Int selectedQuantity
        +String customImageUrl
        +DateTime selectedDeliveryDate
        +String selectedDeliverySlot
        +Int menuOffset
        +DateTime lastActivityAt
        +DateTime lastMessageAt
        +clearCart()
        +updateState(newState, extra)
    }
    class Cake {
        +String id
        +String name
        +String slug
        +String description
        +String image
        +String categoryId
        +Boolean isAvailable
        +Int sortOrder
        +getPublicImageUrl()
    }
    class CakeOption {
        +String id
        +String size
        +String serves
        +Int price
        +Boolean isAvailable
    }
    class Category {
        +String id
        +String name
        +String slug
        +String image
        +Int sortOrder
    }
    class WhatsAppCartItem {
        +String id
        +String phone
        +String cakeName
        +String size
        +Int price
        +Int quantity
        +DateTime createdAt
    }
    class WhatsAppSetting {
        +String key
        +String value
    }
    class Order {
        +String id
        +String orderNumber
        +OrderSource source
        +String customerName
        +String customerPhone
        +String whatsappPhone
        +Int totalPrice
        +String address
        +String notes
        +OrderStatus status
        +PaymentStatus paymentStatus
        +String razorpayOrderId
        +String paymentLink
        +Boolean isCustom
        +String customImageUrl
        +DateTime deliveryDate
        +String deliverySlot
    }
    class OrderItem {
        +String id
        +String cakeName
        +String size
        +Int price
        +Int quantity
    }
    class WhatsAppService {
        +sendTextMessage(phone, text)
        +sendInteractiveButtons(phone, text, buttons)
        +sendInteractiveList(phone, header, body, btnText, sections)
        +sendImageMessage(phone, url, caption)
        +sendCTAUrlButton(phone, body, btnText, url)
        +sendDocumentMessage(phone, url, filename, caption)
        +markAsRead(messageId)
    }
    
    WhatsAppConversation "1" -- "*" WhatsAppCartItem : contains
    WhatsAppConversation "1" -- "*" Order : originated from
    WhatsAppConversation "*" -- "0..1" Cake : selectedCake
    Cake "1" -- "*" CakeOption : has sizes
    Cake "*" -- "0..1" Category : belongs to
    Order "1" -- "*" OrderItem : contains
    OrderItem "*" -- "0..1" Cake : refers to
    WhatsAppConversation --> WhatsAppService : uses
    WhatsAppService ..> WhatsAppSetting : configured by
```

---

## 2. Object Diagram (Structural)
A snapshot of a live session where a user has selected a "Classic Chocolate" cake and is viewing the cart.

```mermaid
classDiagram
    class UserSession_919876543210 {
        phone = "919876543210"
        name = "Priya"
        state = "IDLE"
        selectedCakeId = null
        lastActivityAt = "2026-05-15T10:30:00"
    }
    class CartItem_01 {
        cakeName = "Classic Chocolate"
        size = "0.5 kg"
        price = 75000
        quantity = 1
    }
    class CartItem_02 {
        cakeName = "Red Velvet"
        size = "1 kg"
        price = 120000
        quantity = 2
    }
    UserSession_919876543210 ..> CartItem_01 : cart item 1
    UserSession_919876543210 ..> CartItem_02 : cart item 2
```

---

## 3. Use Case Diagram (Behavioral)
Models the interactions between the customer/admin and the system.

```mermaid
graph LR
    Customer((Customer))
    Admin((Admin))
    
    subgraph WhatsApp Bot System
        UC1(Browse Menu by Category)
        UC2(Select Cake, Size & Quantity)
        UC3(Place Order & Pay)
        UC4(Check Order Status)
        UC5(Design Custom Cake)
        UC6(Cancel / Restart Order)
        UC7(Share Delivery Location)
        UC8(Manage Menu & Categories)
        UC9(Update Order Status)
        UC10(Toggle Maintenance Mode)
        UC11(Configure Delivery Slots)
    end
    
    Customer --> UC1
    Customer --> UC2
    Customer --> UC3
    Customer --> UC4
    Customer --> UC5
    Customer --> UC6
    Customer --> UC7
    
    Admin --> UC8
    Admin --> UC9
    Admin --> UC10
    Admin --> UC11
    Admin --> UC4
```

---

## 4. Sequence Diagram — Complete Order Flow (Behavioral)
Detailed time-ordered flow from browsing to order confirmation.

```mermaid
sequenceDiagram
    participant U as Customer
    participant W as Webhook Route
    participant I as Index Handler
    participant SM as State Machine
    participant M as Menu Handler
    participant C as Cart Handler
    participant D as Delivery Handler
    participant O as Orders Handler
    participant DB as PostgreSQL
    participant Meta as Meta Cloud API
    participant RZP as Razorpay

    U->>Meta: Sends "Hi"
    Meta->>W: POST webhook
    W->>I: handleIncomingMessage(msg)
    I->>I: Dedup + Rate Limit
    I->>SM: _internalHandleMessage(msg)
    SM->>M: sendWelcome(phone)
    M->>DB: safeGetCakes() + safeGetCategories()
    M->>Meta: sendInteractiveList (Welcome)
    M->>Meta: sendDocumentMessage (Menu PDF)
    Meta-->>U: Welcome + PDF

    U->>Meta: Selects "cat_desserts"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>M: handleCategorySelection(msg)
    M->>Meta: sendInteractiveList (Cakes in category)
    Meta-->>U: Cake list

    U->>Meta: Selects "cake_cm4xyz"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>M: handleCakeSelection(msg)
    M->>Meta: sendImageMessage (Cake photo)
    M->>Meta: sendInteractiveButtons (Size options)
    Meta-->>U: Photo + Size buttons

    U->>Meta: Selects "size_0"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>M: handleSizeSelection(msg)
    M->>C: handleCartActions(msg)
    C->>DB: addToCart()
    C->>Meta: sendTextMessage (Added!) + sendInteractiveButtons (Cart)
    Meta-->>U: Cart summary + Checkout buttons

    U->>Meta: Taps "btn_checkout"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>C: handleCartActions(msg)
    C->>DB: Check saved address
    C->>Meta: sendInteractiveButtons (Delivery vs Pickup)
    Meta-->>U: Address choice

    U->>Meta: Taps "btn_delivery"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>Meta: sendTextMessage (Enter address prompt)
    Meta-->>U: Address prompt

    U->>Meta: Sends GPS location
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>D: handleAddressInput(msg)
    D->>D: reverseGeocode(lat, lon)
    D->>Meta: sendInteractiveButtons (Notes prompt)
    Meta-->>U: Cake message prompt

    U->>Meta: Sends "Skip"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>D: handleInstructionsInput(msg)
    D->>D: getAvailableSlots()
    D->>Meta: sendInteractiveList (Delivery slots)
    Meta-->>U: Time slot list

    U->>Meta: Selects "slot_2026-05-16_slot2"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>D: handleDeliverySlotSelection(msg)
    D->>Meta: sendInteractiveButtons (Order Summary + Confirm/Cancel)
    Meta-->>U: Final order summary

    U->>Meta: Taps "btn_confirm"
    Meta->>W: POST webhook
    W->>SM: _internalHandleMessage
    SM->>O: handleConfirmation(msg)
    O->>DB: Create Order + OrderItems
    O->>RZP: createPaymentLink()
    RZP-->>O: short_url
    O->>DB: Save paymentLink
    O->>Meta: sendCTAUrlButton (Pay Now)
    Meta-->>U: Order confirmed + Pay Now button

    U->>RZP: Completes payment
    RZP->>W: POST /api/webhooks/razorpay
    W->>DB: Update Order CONFIRMED + PAID
    W->>Meta: Send premium receipt
    Meta-->>U: Payment receipt
```

---

## 5. Communication Diagram (Behavioral)
Focuses on the organization of objects involved in order creation.

```mermaid
graph TD
    Handler[Message Handler / Index]
    Session[Session Manager]
    SM[State Machine]
    Menu[Menu Service]
    Cart[Cart Service]
    Delivery[Delivery Service]
    Orders[Orders Service]
    Custom[Custom Orders Service]
    DB[(Prisma / PostgreSQL)]
    Meta[Meta Cloud API]
    Cache[In-Memory Cache]
    RZP[Razorpay SDK]
    Supa[Supabase Storage]

    Handler -- "1: dedup + lock" --> Cache
    Handler -- "2: getSession" --> Session
    Session -- "3: query/create" --> DB
    Handler -- "4: route" --> SM
    SM -- "5a: browse" --> Menu
    SM -- "5b: cart ops" --> Cart
    SM -- "5c: address/slots" --> Delivery
    SM -- "5d: confirm" --> Orders
    SM -- "5e: custom" --> Custom
    Menu -- "6: fetch cakes" --> DB
    Cart -- "7: save items" --> DB
    Orders -- "8: create order" --> DB
    Orders -- "9: payment link" --> RZP
    Custom -- "10: upload media" --> Supa
    SM -- "11: respond" --> Meta
```

---

## 6. Activity Diagram — Complete Checkout (Behavioral)
Illustrates the internal logic from checkout to payment.

```mermaid
graph TD
    Start((Checkout Clicked)) --> CheckCart{Cart Empty?}
    CheckCart -- Yes --> ShowMenu[Show Menu] --> End((End))
    CheckCart -- No --> FetchAddr[Fetch Last Saved Address]
    
    FetchAddr --> HasAddr{Has Saved Address?}
    HasAddr -- Yes --> OfferSaved["Offer: Use Previous / New / Pickup"]
    HasAddr -- No --> DirectChoice["Offer: Delivery / Pickup / Back"]
    
    OfferSaved --> UsePrev{User Choice}
    DirectChoice --> UsePrev
    
    UsePrev -- "saved_addr_yes" --> Notes["Prompt: Cake Message"]
    UsePrev -- "btn_delivery" --> EnterAddr["Prompt: Enter Address or GPS"]
    UsePrev -- "btn_pickup" --> SetPickup["Set: Store Pickup"] --> Notes
    
    EnterAddr --> AddrInput{Input Type}
    AddrInput -- "Text" --> Validate[Validate & Sanitize]
    AddrInput -- "GPS Location" --> Geocode["Reverse Geocode + Maps Link"]
    
    Validate --> ValidOk{Valid?}
    ValidOk -- No --> ReAsk[Re-ask for address] --> EnterAddr
    ValidOk -- Yes --> Notes
    Geocode --> Notes
    
    Notes --> NotesInput{User Input}
    NotesInput -- "Skip/No/None" --> NullNotes[Set Notes: null]
    NotesInput -- "Custom Text" --> SaveNotes[Validate & Save Notes]
    
    NullNotes --> Slots[Generate Delivery Slots]
    SaveNotes --> Slots
    
    Slots --> SlotPick[User Picks Slot]
    SlotPick --> Summary["Show Order Summary + Confirm/Back/Cancel"]
    
    Summary --> Decision{User Action}
    Decision -- "btn_confirm" --> CreateOrder["Create Order in DB"]
    Decision -- "btn_cancel" --> ClearCart[Clear Cart + Reset] --> End
    Decision -- "btn_back" --> Slots
    
    CreateOrder --> GenPayment[Generate Razorpay Link]
    GenPayment --> HasLink{Link Generated?}
    HasLink -- Yes --> SendCTA["Send CTA Pay Now Button"]
    HasLink -- No --> SendText["Send Total as Text"]
    
    SendCTA --> End
    SendText --> End
```

---

## 7. State Machine Diagram (Behavioral)
The lifecycle of the User Session, including all flows.

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> BROWSING_MENU: "Menu" / btn_menu
    IDLE --> CUSTOM_ORDER_DETAILS: btn_custom
    IDLE --> CUSTOM_ORDER_IMAGE: "design my own cake"
    IDLE --> SELECTING_SIZE: Fuzzy cake match / Direct order
    
    state BROWSING_MENU {
        [*] --> SmallMenu: Total cakes ≤ 10
        [*] --> CategoryList: Total cakes > 10
        CategoryList --> CategoryList: morecat_ / prevcat_
    }
    
    BROWSING_MENU --> SELECTING_CATEGORY: cat_id selected
    
    state SELECTING_CATEGORY {
        [*] --> CakeList
        CakeList --> CakeList: more_ / prev_
    }
    
    SELECTING_CATEGORY --> SELECTING_SIZE: cake_id selected
    SELECTING_SIZE --> SELECTING_QUANTITY: size_idx selected
    SELECTING_QUANTITY --> IDLE: Auto-add to cart (shows cart summary)
    
    IDLE --> INPUTTING_ADDRESS: btn_checkout
    
    state INPUTTING_ADDRESS {
        [*] --> OfferSaved: Has previous address
        [*] --> DeliveryChoice: No previous address
        OfferSaved --> UseText: btn_delivery
        DeliveryChoice --> UseText: btn_delivery
    }
    
    INPUTTING_ADDRESS --> ADDING_NOTES: Address / Location / Pickup / Saved
    ADDING_NOTES --> ASKING_DELIVERY_DATE: Notes / Skip
    ASKING_DELIVERY_DATE --> CONFIRMING_ORDER: Slot selected
    CONFIRMING_ORDER --> IDLE: btn_confirm (Order Created)
    CONFIRMING_ORDER --> IDLE: btn_cancel (Cancelled)
    
    CUSTOM_ORDER_DETAILS --> CUSTOM_ORDER_IMAGE: Text description
    CUSTOM_ORDER_DETAILS --> IDLE: Image (Order Created)
    CUSTOM_ORDER_IMAGE --> IDLE: Image (Order Created)
    
    SELECTING_SIZE --> BROWSING_MENU: btn_back
    SELECTING_QUANTITY --> SELECTING_SIZE: btn_back
    ADDING_NOTES --> INPUTTING_ADDRESS: btn_back
    ASKING_DELIVERY_DATE --> ADDING_NOTES: btn_back
    CONFIRMING_ORDER --> ASKING_DELIVERY_DATE: btn_back
    
    BROWSING_MENU --> IDLE: "Cancel" / "Restart"
```

---

## 8. Component Diagram (Structural)
High-level software components and their dependencies.

```mermaid
graph BT
    subgraph "Webhook Layer (API Routes)"
        WA_API["WhatsApp Webhook<br/>/api/webhooks/whatsapp"]
        RZP_API["Razorpay Webhook<br/>/api/webhooks/razorpay"]
        CRON_API["Cleanup Cron<br/>/api/cron/cleanup"]
    end
    
    subgraph "Core Logic (Conversation Handler)"
        IDX[Index - Dedup, Lock, Rate Limit]
        SM[State Machine - Global Interceptors]
        MENU[Menu Service - Browsing, Search]
        CART[Cart Service - CRUD, Summary]
        DELIVERY[Delivery - Address, Slots, Geocoding]
        ORDERS[Orders - Creation, Payment, Status]
        CUSTOM[Custom Orders - Text + Image Flow]
        SESSION[Session Manager + Config]
    end
    
    subgraph "Data Layer"
        CACHE[In-Memory Cache]
        PRISMA[Prisma Client]
        RATE[Rate Limiter]
    end
    
    subgraph "External Services"
        DB[(PostgreSQL / Supabase)]
        STORAGE[Supabase Storage]
        META_API[Meta Cloud API v18.0]
        RZP_SDK[Razorpay Node SDK]
        NOM[Nominatim Geocoding API]
    end
    
    WA_API --> IDX
    RZP_API --> PRISMA
    CRON_API --> PRISMA
    
    IDX --> CACHE
    IDX --> RATE
    IDX --> SM
    
    SM --> MENU
    SM --> CART
    SM --> DELIVERY
    SM --> ORDERS
    SM --> CUSTOM
    SM --> SESSION
    
    SESSION --> PRISMA
    SESSION --> CACHE
    MENU --> PRISMA
    CART --> PRISMA
    ORDERS --> PRISMA
    ORDERS --> RZP_SDK
    CUSTOM --> STORAGE
    DELIVERY --> NOM
    
    PRISMA --> DB
    SM --> META_API
```

---

## 9. Deployment Diagram (Structural)
The physical nodes where the system is deployed.

```mermaid
graph TD
    subgraph User_Device ["User Device"]
        WA[WhatsApp App]
    end
    
    subgraph Meta_Infra ["Meta Infrastructure"]
        CloudAPI[Meta Cloud API v18.0]
    end
    
    subgraph Vercel_Platform ["Vercel (Edge/Serverless)"]
        NextJS["Next.js 15.5+ App Router"]
        Node["Node.js 20+ Runtime"]
        Cron["Vercel Cron (Daily)"]
    end
    
    subgraph Supabase_Cloud ["Supabase Cloud"]
        PG[(PostgreSQL DB)]
        Storage["Supabase Storage<br/>(cakes bucket)"]
    end
    
    subgraph Razorpay_Infra ["Razorpay"]
        RZP_API["Payment Links API"]
        RZP_WH["Payment Webhooks"]
    end
    
    subgraph OSM ["OpenStreetMap"]
        Nominatim["Nominatim Geocoding"]
    end
    
    WA <--> CloudAPI
    CloudAPI <--> NextJS
    NextJS --- PG
    NextJS --- Storage
    NextJS --- RZP_API
    RZP_WH --> NextJS
    Cron --> NextJS
    NextJS --- Nominatim
```

---

## 10. Custom Order Flow — Activity Diagram (Behavioral)
Detailed flow for the custom cake ordering process.

```mermaid
graph TD
    Start((Start)) --> Entry{Entry Point}
    
    Entry -- "btn_custom" --> DescPrompt["Prompt: Describe your cake"]
    Entry -- '"design my own cake"' --> PhotoPrompt["Prompt: Upload Reference Photo"]
    Entry -- "Image outside flow" --> Offer["Offer: Start Custom Order?"]
    
    Offer -- "btn_custom" --> DescPrompt
    
    DescPrompt --> UserInput{User sends...}
    UserInput -- "Text" --> CheckText{Looks like address?}
    UserInput -- "Image" --> Download["Download from Meta API"]
    
    CheckText -- "No" --> SaveNotes["Save as description"]
    CheckText -- "Yes (numbers + >3 words)" --> SaveAddr["Save as address"]
    
    SaveNotes --> PhotoPrompt
    SaveAddr --> PhotoPrompt
    
    PhotoPrompt --> ImgUpload{User sends image?}
    ImgUpload -- "Yes" --> Download
    ImgUpload -- "No (text)" --> ReAsk["Re-prompt for photo"]
    
    Download --> Upload["Upload to Supabase Storage<br/>cakes/custom-requests/"]
    Upload --> Success{Upload OK?}
    Success -- "Yes" --> CreateOrder["Create Order with public URL"]
    Success -- "No" --> FallbackOrder["Create Order with whatsapp://media fallback"]
    
    CreateOrder --> Confirm["Show Reference # + Buttons"]
    FallbackOrder --> Confirm
    Confirm --> End((End))
```
