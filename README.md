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

The User represents the model, UserService is the sole class that interacts with the API/SharedPreferences for authentication data, and ProfileScreen simply requests UserService().getUser() for the logged-in user and shows it — following the same Repository/Service structure as Labs 2-3, now utilized for /auth/login. The revised pattern includes a persistence layer: UserService stores the login response in SharedPreferences and retrieves it later, allowing the service to function as a local cache in front of the API rather than contacting it on every screen. The saved user id is now what scopes the cart: CartScreen no longer directly calls CartService.getCartsByUser with a hardcoded demo id as it did in Lab 3 — it first retrieves UserService().getUser().id and then sends that actual id into getCartsByUser, ensuring the displayed cart always belongs to the signed-in user.


## Lab Activity 5: Discussion

The sign-in screen accepts an email or username without requiring the user to select an authentication provider. Firebase Authentication handles email accounts, while DummyJSON handles username accounts. The profile screen allows users to update their username, and logout requires confirmation before clearing the session. Keeping authentication logic in UserService and account details in the profile screen makes the account flow easier to maintain.

