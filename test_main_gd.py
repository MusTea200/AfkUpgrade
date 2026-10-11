import re

with open('Main.gd', 'r') as f:
    content = f.read()

# Check for tooltip_text assignment
assert 'btn.tooltip_text = tooltip.strip_edges()' in content, "Missing tooltip_text assignment"

# Check for loop structure to ensure indentation wasn't completely broken
assert 'for item in task.input_items:' in content, "Missing input items loop"
assert 'for item in task.output_items:' in content, "Missing output items loop"

print("GDScript checks passed.")
