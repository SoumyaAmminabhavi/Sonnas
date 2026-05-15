# Comprehensive UML Documentation for WhatsApp Bot

This document provides a full suite of UML diagrams describing the structural and behavioral aspects of the Sonna's Patisserie WhatsApp Bot.

---

## 1. Class Diagram (Structural)
Defines the core data models and service relationships.

```mermaid
classDiagram
    class WhatsAppConversation {
        +String phone
        +ConversationState state
        +String selectedCakeId
        +DateTime lastActivityAt
        +clearCart()
        +updateState(newState)
    }
    class Cake {
        +String id
        +String name
        +String slug
        +Float basePrice
        +getPublicImageUrl()
    }
    class WhatsAppSetting {
        +String key
        +String value
    }
    class Order {
        +String orderId
        +OrderStatus status
        +Float totalAmount
        +processPayment()
    }
    class WhatsAppService {
        +sendText(phone, text)
        +sendButtons(phone, text, buttons)
        +sendImage(phone, url, caption)
    }
    
    WhatsAppConversation "1" -- "*" WhatsAppCartItem : contains
    WhatsAppCartItem "*" -- "1" Cake : refers to
    WhatsAppConversation --> WhatsAppService : uses
    Order "1" -- "1" WhatsAppConversation : originated from
    WhatsAppService ..> WhatsAppSetting : configured by
```

---

## 2. Object Diagram (Structural)
A snapshot of a live session where a user is ordering a "Classic Chocolate" cake.

```mermaid
classDiagram
    class UserSession_919876543210 {
        phone = "919876543210"
        state = "SELECTING_SIZE"
        selectedCakeId = "cake_choc_01"
    }
    class ActiveItem_01 {
        cakeName = "Classic Chocolate"
        quantity = 1
        size = "0.5kg"
    }
    UserSession_919876543210 ..> ActiveItem_01 : instance of
```

---

## 3. Use Case Diagram (Behavioral)
Models the interactions between the customer/admin and the system.

```mermaid
graph LR
    Customer((Customer))
    Admin((Admin))
    
    subgraph WhatsApp Bot System
        UC1(Browse Menu)
        UC2(Select Cake & Size)
        UC3(Place Order)
        UC4(Check Order Status)
        UC5(Design Custom Cake)
        UC6(Manage Menu)
        UC7(Update Order Status)
    end
    
    Customer --> UC1
    Customer --> UC2
    Customer --> UC3
    Customer --> UC4
    Customer --> UC5
    
    Admin --> UC6
    Admin --> UC7
    Admin --> UC4
```

---

## 4. Sequence Diagram (Behavioral)
Detailed time-ordered flow of adding an item to the cart, including dynamic setting lookup.

```mermaid
sequenceDiagram
    participant U as User
    participant W as Webhook
    participant S as StateMachine
    participant D as Database
    participant M as Meta API

    U->>W: Clicks "Select Size: 0.5kg"
    W->>S: handleSizeSelection(msg)
    S->>D: getWhatsAppSetting("SESSION_TIMEOUT")
    D-->>S: 60 mins
    S->>D: Create WhatsAppCartItem
    D-->>S: Success
    S->>D: Update ConversationState to SELECTING_QUANTITY
    S->>M: sendMessage("How many units?")
    M-->>U: Shows Quantity Buttons
```

---

## 5. Communication Diagram (Behavioral)
Focuses on the organization of objects involved in order creation.

```mermaid
graph TD
    Handler[Message Handler]
    Session[Session Manager]
    Cart[Cart Service]
    DB[(Prisma DB)]
    Meta[Meta Service]

    Handler -- "1: getSession" --> Session
    Session -- "2: query" --> DB
    Handler -- "3: addItem" --> Cart
    Cart -- "4: save" --> DB
    Handler -- "5: respond" --> Meta
```

---

## 6. Activity Diagram (Behavioral)
Illustrates the internal logic of the "Add to Cart" workflow.

```mermaid
graph TD
    Start((Start)) --> Rec[Receive Message]
    Rec --> Val{Valid Input?}
    Val -- No --> Err[Send Error Message] --> End((End))
    Val -- Yes --> CheckState{Current State?}
    
    CheckState -- BROWSING --> ShowItems[Fetch Category Items]
    CheckState -- SELECTING_SIZE --> SaveItem[Update Cart in DB]
    
    SaveItem --> NextState[Determine Next State]
    NextState --> Resp[Build Interactive Response]
    Resp --> Send[Dispatch to Meta API]
    Send --> End
```

---

## 7. State Machine Diagram (Behavioral)
The lifecycle of the User Session, including Custom Order flows.

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> BROWSING_MENU: "Menu"
    BROWSING_MENU --> SELECTING_SIZE: Cake Selected
    SELECTING_SIZE --> SELECTING_QUANTITY: Size Selected
    SELECTING_QUANTITY --> CONFIRMING_ORDER: Quantity Selected
    CONFIRMING_ORDER --> IDLE: Order Placed
    
    IDLE --> CUSTOM_ORDER_START: "Design my own cake"
    CUSTOM_ORDER_START --> CUSTOM_ORDER_IMAGE: Details Provided
    CUSTOM_ORDER_IMAGE --> CUSTOM_ORDER_DETAILS: Photo Uploaded
    CUSTOM_ORDER_DETAILS --> CONFIRMING_ORDER: Final Review
    
    state BROWSING_MENU {
        [*] --> ListCategories
        ListCategories --> ListItems: Category Picked
    }
    
    BROWSING_MENU --> IDLE: "Cancel"
    SELECTING_SIZE --> BROWSING_MENU: "Back"
```

---

## 8. Component Diagram (Structural)
High-level software components and their dependencies.

```mermaid
graph BT
    subgraph Webhook Layer
        API[API Route Handlers]
    end
    
    subgraph Core Logic
        Handler[Conversation Handler]
        SM[State Machine]
    end
    
    subgraph Data Layer
        Prisma[Prisma Client]
        Cache[In-Memory Cache]
    end
    
    API --> Handler
    Handler --> SM
    Handler --> Cache
    SM --> Prisma
    Prisma --> DB[(PostgreSQL)]
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
        CloudAPI[Meta Cloud API]
    end
    
    subgraph Vercel_Platform ["Vercel (Edge/Serverless)"]
        NextJS[Next.js App]
        Node[Node.js Runtime]
    end
    
    subgraph Supabase_Cloud ["Supabase Cloud"]
        PG[(PostgreSQL DB)]
        Storage[Supabase Storage]
    end
    
    WA <--> CloudAPI
    CloudAPI <--> NextJS
    NextJS --- PG
    NextJS --- Storage
```
