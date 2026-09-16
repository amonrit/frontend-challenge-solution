# RES-103 — Questions Before Evidence and Task Breakdown

## 1. Required outcome and acceptance

1. What exact user journey must stop producing requests from closed deal pages?
2. Must every closed detail controller stop observing the cart immediately, or
   is it acceptable for cleanup to happen when its route is removed?
3. Should an active detail page still refresh its availability after a cart
   change?
4. What evidence is sufficient to prove that only currently active detail
   pages can issue the refresh request?
5. Is the ticket limited to the cart observer, or should other controller
   resources on the detail page be audited as part of the fix?

## 2. Reproduction and request behavior

1. Can the request burst be reproduced reliably on the current revision?
2. What exact sequence of detail-page opens, closes, and **Add to bag** taps
   produces the burst?
3. Does opening the same deal repeatedly create one request per closed page?
4. Does the burst occur after closing pages with Back, swipe navigation, or
   route replacement?
5. Does it occur when the cart changes from the cart screen rather than from a
   detail page?
6. Does an empty-cart to non-empty transition behave differently from a
   quantity increment or decrement?
7. Are requests emitted only after the cart observable changes, or also during
   controller initialization?
8. How many `GET /deals/:id` requests are logged after one, two, and several
   detail pages have been closed?
9. Does a request from a closed page update any visible state or produce an
   error after the route is gone?

## 3. Controller, route, and observer lifecycle

1. Which object creates the cart observer and which object owns its cleanup?
2. What concrete Worker type does `ever(...)` return in the pinned GetX version?
3. When does GetX call `DealDetailsController.onClose()` for a pushed detail
   route?
4. Is the controller disposed on every route-removal path used by the app?
5. Can a controller remain registered or reused after its detail screen closes?
6. Are there other Workers, subscriptions, timers, or controllers in the same
   route that affect the request count?
7. What happens if a cart change occurs while a detail controller is closing?
8. What happens if a request is already in flight when the detail controller
   is disposed?
9. Should an in-flight response be ignored after disposal, or is cleanup of
   the observer alone sufficient for this ticket?

## 4. Scope, constraints, and compatibility

1. Which files are allowed to change for the smallest correct fix?
2. Must the fix preserve the current `quantityLeft` update behavior and UI?
3. Can the behavior be tested with fake repositories and a fake cart service?
4. Does the pinned GetX version impose a specific Worker-disposal pattern?
5. Must RES-103 remain separate from RES-107 and reservation/flash-sale work?
6. Should a shared observer-management abstraction be considered, or would it
   broaden the ticket unnecessarily?

## 5. Edge cases

1. What happens when the user opens and closes the same detail page rapidly?
2. What happens when several detail pages are open at the same time?
3. What happens when the cart changes while no detail page is visible?
4. What happens when the detail page fails its initial deal load or has no deal?
5. What happens when multiple cart changes occur before an availability request
   completes?
6. What happens when a detail page is disposed during a slow API response?
7. What happens when the app is backgrounded and then resumed with detail pages
   in the navigation stack?

## 6. Test and evidence design

1. What focused test can prove that a live controller reacts to a cart change?
2. What focused test can prove that a disposed controller no longer reacts?
3. How can the test count repository `fetchById` calls without using the real
   fake API service?
4. How can route push/pop be tested to cover GetX controller disposal?
5. What failure signal should the RED test show before the fix?
6. What GREEN assertions prove both retained active behavior and cleanup?
7. How should the test cover several detail controllers without depending on
   real network latency?
8. Which console-log or API-call evidence should be retained from manual
   reproduction?
9. Which targeted tests, full-suite checks, and analyzer checks are required
   before delivery?
