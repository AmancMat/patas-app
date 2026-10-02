<div align="center">

# 🐾 Patas — The All-in-One Web3 Pet Ecosystem
### Social Network, Veterinary Healthcare, Shelter Transparency & Solana Pay

[![Solana](https://img.shields.io/badge/Solana-Devnet%20%26%20Mainnet-14F195?style=for-the-badge&logo=solana&logoColor=black)](https://solana.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.9%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Live Demo](https://img.shields.io/badge/Live%20Demo-patas.online-FF6F00?style=for-the-badge)](https://patas.online/)
[![Hackathon](https://img.shields.io/badge/Colosseum%20Hackathon-Submission-9945FF?style=for-the-badge)](https://colosseum.com)

**[🌐 Access Live Web Application (Production)](https://patas.online/)**

</div>

---

## 📌 Executive Summary

**Patas** is a production-grade, multi-platform consumer SuperApp (Flutter Web & Mobile) engineered to modernize the global pet care market ($260B+). It bridges everyday pet parenting (social networking, veterinary records, preventive health) with **real-world Web3 utilities on Solana**: zero-fee transparent donations for animal shelters, immutable digital pet passports via Compressed NFTs, and community rescue alerts.

---

## ⚡ Solana Integrations (Live in Production)

### 1. 💖 Transparent Shelter Donations via Solana Pay (`Patas Acolhe`)
* **Sub-second Settlement (400ms) & Zero Intermediary Fees:** Donors worldwide can send micro-donations in **USDC** or **SOL** directly to vetted animal shelters.
* **Frictionless Web2.5 UX:** Generates canonical Solana Pay QR Codes with instant on-chain detection via RPC listeners.
* **Mobile Deep-Linking:** One-tap redirect to mobile wallets (**Phantom / Solflare**) with auto-fallback and guidance.
* **On-Chain Audit Trail:** Every contribution is permanently verified and displayed with direct links to the Solana Explorer.

### 2. 📜 Immutable Pet Passport via Compressed NFTs (cNFTs)
* **Bubblegum State Compression:** Employs Metaplex compressed NFTs to mint tamper-proof digital certificates containing pet ISO microchip IDs, breed, pedigree, and verified rabies/polyvalent vaccinations.
* **Ultra-Low Cost Identity:** Enables shelters and clinics to anchor hundreds of thousands of pet medical milestones on Solana for a fraction of a cent.

### 3. 🏷️ Smart Search Tags & Lost Pet Alerts (`Patas Encontra`)
* Physical smart tags (QR/NFC) integrated with geolocation scan tracking and automated emergency broadcast to nearby community members and shelters.

---

## 📱 The Complete Pet SuperApp Modules

* **🐾 Pet-Centric Social Feed:** Stories, interactive posts, community shares, and localized pet-friendly discovery.
* **🏥 Veterinary Health Hub:** Vaccine calendars, medication reminders, appointment scheduling, and full medical timelines.
* **🏠 Shelter Management SaaS:** Intake pipelines, foster home matching (*Lares Temporários*), collective kennel medical records, and adoption approvals.
* **🗺️ Interactive Pet-Friendly Map:** Geocoded parks, pet shops, veterinary hospitals, and animal-welcoming establishments.

---

## 🛠️ Architecture & Tech Stack

* **Frontend:** Flutter (Dart) with responsive multi-screen engine (Mobile, Tablet, Desktop/Web).
* **Blockchain Layer:** Solana RPC (Devnet / Mainnet), Solana Pay Protocol, Metaplex Bubblegum cNFT specification.
* **Backend & Storage:** Supabase (PostgreSQL with Row Level Security, Edge Functions, Realtime websockets, and encrypted Cloud Storage).
* **Notifications:** Omnichannel FCM v1 push notifications, Chrome Web Push, and In-App notification center with idempotency locking.

---

## 🚀 Getting Started Locally

### Prerequisites
* Flutter SDK (3.24.x or higher)
* Dart SDK (3.5.x or higher)
* Chrome or Android Studio / Emulator

### Installation & Run

```bash
# 1. Clone the repository
git clone https://github.com/AmancMat/patas-app.git
cd patas-app

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Fill in your Supabase & RPC endpoints in .env

# 4. Run on Chrome (Web)
flutter run -d chrome

# Or run on Android
flutter run -d android
```

---

## 📄 License & Intellectual Property

Copyright © 2026 Origem Studio / Patas App.  
Developed for the **Solana Colosseum Hackathon** & **Superteam Brasil**.
