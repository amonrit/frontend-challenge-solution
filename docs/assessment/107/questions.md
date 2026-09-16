# RES-107 — Questions Before Evidence and Task Breakdown

## 1. Required outcome and acceptance

1. Which URI forms must resolve to the deal details route, and which route
   parameters are required versus optional?
2. What does “fully working deal page” include while data loads, after data
   loads, and when the deal cannot be loaded?
3. Must a deep link support both a cold app start and navigation while the app
   is already running?
4. What behavior must remain unchanged for navigation from Home, Search, and
   the flash-sale rail?
5. Is the required success case limited to deal 42, or must every valid deal ID
   follow the same contract?
6. What user-visible behavior is required for a malformed, missing, nonnumeric,
   or unknown deal ID?

## 2. Reproduction and routing facts

1. What exact route string does the in-app deep-link simulator pass to GetX for
   `rescu://open/deal?id=42&source=push`?
2. Does GetX populate `Get.parameters` consistently for the in-app route and
   the Android intent route?
3. Is an in-app deal card navigation carrying a `DealModel` through
   `Get.arguments`, and does the deep-link flow intentionally omit it?
4. Which line throws the observed `Null`-to-`DealModel` cast error?
5. Does the current route binding create a fresh details controller for each
   navigation path?
6. Can a second deep link arrive while the first ID-based details request is
   still loading?

## 3. State ownership and lifecycle

1. Which layer should decide whether an already-provided route argument is a
   usable `DealModel` versus an ID that must be fetched?
2. Which state must the details controller expose to render loading, loaded,
   and failure states without forced casts?
3. How should the controller parse and validate the route ID before requesting
   the repository?
4. When the route closes during an ID fetch, may its completion still mutate
   controller state or display an error?
5. If cart changes while a deep-link deal is still loading, when should the
   availability observer start?
6. How must analytics obtain `deal_id` and `source` when the details model is
   not yet loaded?

## 4. Repository and error behavior

1. What exception and status information does `DealRepo.fetchById` preserve for
   a missing deal?
2. Can the repository return a partial or invalid `DealModel`, or only a model
   or error?
3. Does the API call for a valid ID include simulated latency that requires a
   loading state in the UI?
4. How should technical error details be logged and how should a user-facing
   failure state be phrased?
5. Is retry required by the assignment, desirable as a scoped improvement, or
   outside this ticket?

## 5. Edge cases and compatibility

1. A valid deep link supplies `id=42` and `source=push` but no arguments.
2. A valid route uses a numeric ID with no `source` parameter.
3. A route supplies a nonnumeric or absent ID.
4. The ID parses but the repository returns a not-found error.
5. A normal card route provides both an ID parameter and a `DealModel`
   argument.
6. Route arguments have an unexpected runtime type.
7. The user backs out while the ID fetch is still in flight.
8. A late fetch response follows navigation to a different deal.
9. An availability refresh fails after a valid deep-link deal initially loads.

## 6. Test and evidence design

1. What focused controller test can reproduce the current missing-argument
   failure without relying on a running simulator?
2. How can a fake repository control successful, delayed, and failed
   `fetchById` responses?
3. Which assertions prove that a valid ID route reaches loaded state and
   preserves the correct `source`?
4. Which assertions prove normal `DealModel` argument navigation still works?
5. What test distinguishes invalid route input from repository not-found
   failure?
6. Which widget or integration test is necessary to prove loading and error UI
   states, rather than controller state alone?
7. Which manual flow should verify the overflow-menu simulation for deal 42?
8. What logs, screenshots, and quality-gate commands are needed before
   delivery?
