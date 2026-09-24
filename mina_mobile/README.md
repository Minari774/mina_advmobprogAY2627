# Mina, Luigi Caezar F.

## INF 233 MWA

## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advanced topics, including mobile-to-web transactions.

## Lab Activity Instance

## Lab Activity 2: Discussion

ProductService handles the API requests, while Product converts JSON data into Dart objects. The screen gets the data through the service instead of calling HTTP directly. This follows the Repository/Service pattern, making API changes easier to manage.

## Lab Activity 3: Discussion

`Cart` and `CartProduct` convert cart JSON into Dart objects, while `CartService` handles the API Cart and CartProduct convert cart JSON into Dart objects, while CartService handles API requests. CartScreen gets the user's cart through CartProvider. Selecting an item uses ProductService.getProductById() and opens the existing ProductDetailScreen. The Add to Cart button sends the product and user details to the API, while CartProvider updates the cart locally. getCartById() retrieves a specific cart. Lastly, Chat was moved to a FloatingActionButton and is hidden on the Cart screen..
