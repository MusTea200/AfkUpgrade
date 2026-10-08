## 2024-10-08 - Task Affordability Feedback
**Learning:** Setting `disabled = not task.can_start()` and updating it dynamically on inventory changes gives crucial visual feedback, preventing users from clicking unavailable actions in resource-based idle games. Storing the `task` as metadata (`set_meta`) is an effective way to re-evaluate state later.
**Action:** Always bind the disabled state of actionable buttons to their underlying affordability logic, and ensure the state recalculates whenever dependent resources change.
