# RES-106 — Questions Before Evidence and Task Breakdown

## 1. Required outcome and acceptance

1. Which market timezone must all pickup display and date-filter decisions use?
2. Should a UTC instant be displayed as Bangkok local wall-clock time in every
   screen, card, map, and notification entry point?
3. What exact text should a pickup window such as `06:00–09:30` display after
   conversion from UTC?
4. What does **Pickup today** mean when the pickup window starts today but ends
   after midnight?
5. Should “today” be based on the device's current calendar date or the
   market's Bangkok calendar date?
6. What behavior is required when the pickup window is exactly at midnight?

## 2. Current behavior and reproduction

1. Which source timestamps demonstrate the bakery `06:00–09:30` complaint?
2. Are the parsed `DateTime` values marked UTC, local, or unspecified after
   `DateTime.parse`?
3. Which screens and models use `PickupWindowModel.label`, `isToday`,
   `isOpenNow`, or `untilStart`?
4. Can the reported wrong display be reproduced on a machine whose local
   timezone is not Bangkok?
5. What fixed UTC instant and local timezone should reproduce the filter
   omission around midnight?
6. Does the issue occur across month and year boundaries, or only when the
   numeric day is equal in different months?

## 3. Timezone policy and ownership

1. Should the application use a named IANA timezone such as
   `Asia/Bangkok`, a fixed `UTC+07:00` offset, or the device timezone?
2. Does the current dependency set provide named timezone conversion, or would
   adding a package be allowed under the no-upgrade constraint?
3. Where should conversion occur: repository/model parsing, a date utility, or
   each presentation widget?
4. Should model fields remain UTC instants internally after parsing?
5. Which component owns the “now” clock for `isToday`, `isOpenNow`, and tests?
6. How should invalid or missing timestamp strings be handled?

## 4. Date and boundary semantics

1. Must `isToday` compare year, month, and day after conversion to Bangkok?
2. What should happen for a window that starts before Bangkok midnight and ends
   after it?
3. What should happen exactly at the start and end instants for `isOpenNow`?
4. How should UTC dates that convert to the previous or next Bangkok day be
   represented?
5. Are there any historical or future timezone-rule changes that matter for the
   catalog data?
6. Should date formatting use 24-hour time everywhere, including overnight
   windows?

## 5. Compatibility and edge cases

1. Must existing order, reservation, and flash-sale timestamps keep their
   current semantics outside RES-106?
2. Should a device configured to another timezone still see Bangkok pickup
   times and the Bangkok “today” filter?
3. What should happen when `start` and `end` are on different local dates?
4. Should the filter include a deal whose pickup window is already closed but
   started today?
5. Should the filter include a deal whose window starts just after midnight
   Bangkok time but is still the previous UTC date?

## 6. Test and evidence design

1. Should the regression be model unit tests, HomeController tests, widget
   tests, or a combination?
2. What clock and timezone seams make tests deterministic without changing
   production behavior unexpectedly?
3. Which fixed UTC timestamps cover normal conversion, Bangkok midnight,
   month-end, year-end, and overnight windows?
4. How will the test prove that the filter compares complete calendar dates,
   not only the numeric day?
5. What before measurement should be recorded for the wrong label and omitted
   filtered deal?
6. What after measurement should demonstrate correct local text and filter
   membership on the same inputs?
7. Which full-suite, analyzer, diff, and manual checks are required before
   marking RES-106 complete?
