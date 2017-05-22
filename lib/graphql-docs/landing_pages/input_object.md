---
title: Input Objects
---

# Input Objects

Input objects are best described as "composable objects" in that they contain a set of input fields that define a particular object. For example, the `AuthorInput` takes a field called `emails`. Providing a value for `emails` will transform the `AuthorInput` into a list of `User` objects which contain that email address/

For more information, see [the GraphQL spec](https://facebook.github.io/graphql/#sec-Input-Objects).
