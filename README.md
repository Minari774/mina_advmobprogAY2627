# Luigi Caezar F. Mina

## INF 233 MWA

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance

## Lab Activity 1: Discussion

- **Lab 1 - Theme(Dark/Light Mode)**: The project used setState for the counter screen. This is because setState only updates the state within a widget. It is simple and suitable for changes like increasing or decreasing a counter.
In contrast the project used Provider for the apps theme. Provider allows the state to be shared across the application. Any screen can. Update the state when using Provider.
Provider is different, from setState. SetState resets when the widget is removed or rebuilt. On the hand Provider preserves the shared state. This means the state is preserved when switching between screens with Provider. The project used Provider for this reason. 

## Lab Activity 2: Discussion

ProductService handles the API requests, while Product converts JSON data into Dart objects. The screen gets the data through the service instead of calling HTTP directly. This follows the Repository/Service pattern, making API changes easier to manage.

## Lab Activity 3: Discussion

`Cart` and `CartProduct` convert cart JSON into Dart objects, while `CartService` handles the API Cart and CartProduct convert cart JSON into Dart objects, while CartService handles API requests. CartScreen gets the user's cart through CartProvider. Selecting an item uses ProductService.getProductById() and opens the existing ProductDetailScreen. The Add to Cart button sends the product and user details to the API, while CartProvider updates the cart locally. getCartById() retrieves a specific cart. Lastly, Chat was moved to a FloatingActionButton and is hidden on the Cart screen..

## Lab Activity 4: Discussion

`User` represents profile data, and `UserService` owns authentication, provider selection, session handling, and profile retrieval. Screens collect and validate input, then call the service; they do not make authentication requests directly. This follows the same service pattern as the product and cart features.


## Lab Activity 5: Discussion

The sign-in screen now accepts an email or username without asking the user to choose an authentication provider. Email addresses are checked with Firebase Authentication first, while usernames use DummyJSON; email-shaped DummyJSON usernames can fall back to that service. The profile screen displays the signed-in user's information and lets them update their username. Logout asks for confirmation before clearing the active session. These changes make authentication and account actions clearer while keeping provider-specific work in `UserService`.

The floating chat button opens a searchable directory of other Firebase users. Chat profiles are stored in Firestore, and one-to-one messages use a shared room with sender, receiver, timestamp, and delivery status fields. The chat screen animates new messages and shows sending, sent, delivered, and seen states. Chat requires a Firebase account; DummyJSON demo accounts do not have a Firebase identity. Existing Firebase users are added to the directory when they next sign in. Deploy the updated rules from `mina_mobile` with `firebase deploy --only firestore:rules` before using chat.

## Lab Activity 6: Discussion

Firestore stores user profiles in `users/{uid}`, conversations in `chat_rooms/{sortedUidPair}`, and their messages in each room's `messages` subcollection. The chat list hides the signed-in user, and the app and Firestore rules reject self-chat, preventing duplicate conversations with oneself.
