def generate_receipt(data, char_width):
    """
    Generate a thermal receipt string based on the RAGA PVT LTD template.

    Args:
        data: Dictionary containing receipt data
        char_width: Integer representing characters per line (e.g., 48 for 80mm, 32 for 58mm)

    Returns:
        String representation of the formatted receipt
    """
    lines = []

    # Helper functions
    def center_text(text):
        return text.center(char_width)

    def left_right_align(left, right):
        return f"{left:<{char_width - len(str(right))}}{right}"

    def format_currency(amount):
        return f"Rs {amount:.2f}"

    # Calculate column widths for item table
    # Item name gets most space, Qty and Amt get fixed widths
    qty_width = 5
    amt_width = 10
    item_width = char_width - qty_width - amt_width - 2  # -2 for spaces between columns

    # 1. Header (Centered)
    lines.append(center_text(data['store_name']))
    for addr_line in data['address']:
        lines.append(center_text(addr_line))
    lines.append("")  # Blank line
    lines.append(center_text(data['title']))
    lines.append("")  # Blank line

    # 2. Metadata (Left-Aligned)
    lines.append(f"Date : {data['date']}, {data['time']}")
    lines.append(data['customer'])
    lines.append("")  # Blank line
    lines.append(f"Bill No: {data['bill_no']}")
    lines.append(f"Payment Mode: {data['payment_mode']}")
    lines.append(f"DR Ref : {data['dr_ref']}")

    # 3. Item Table
    # Header
    header = f"{'Item':<{item_width}} {'Qty':>{qty_width}} {'Amt':>{amt_width}}"
    lines.append(header)

    # Separator
    lines.append("." * char_width)

    # Item rows
    for item in data['items']:
        item_line = f"{item['name']:<{item_width}} {item['qty']:>{qty_width}} {item['amt']:>{amt_width}.2f}"
        lines.append(item_line)

    # Separator
    lines.append("-" * char_width)

    # 4. Summary
    # Sub Total
    sub_total_line = f"{'Sub Total':<{item_width}} {data['sub_total_qty']:>{qty_width}} {data['sub_total_amt']:>{amt_width}.2f}"
    lines.append(sub_total_line)

    # Discount
    discount_line = f"{'(-) Discount':<{char_width - amt_width - 1}} {data['discount']:>{amt_width}.2f}"
    lines.append(discount_line)

    # Taxes
    for tax in data['taxes']:
        tax_line = f"{tax['name']:<{char_width - amt_width - 1}} {tax['amt']:>{amt_width}.2f}"
        lines.append(tax_line)

    # 5. Total
    lines.append("=" * char_width)
    total_line = f"{'TOTAL':<{char_width - amt_width - 1}} {format_currency(data['total']):>{amt_width}}"
    lines.append(total_line)
    lines.append("=" * char_width)

    # 6. Payment
    cash_line = f"{'Cash :':<{char_width - amt_width - 1}} {format_currency(data['cash']):>{amt_width}}"
    lines.append(cash_line)

    cash_tendered_line = f"{'Cash tendered:':<{char_width - amt_width - 1}} {format_currency(data['cash_tendered']):>{amt_width}}"
    lines.append(cash_tendered_line)

    # 7. Footer
    lines.append("")
    lines.append(data['footer'].rjust(char_width))

    return "\n".join(lines)


# Example usage with the provided data
data = {
    "store_name": "RAGA PVT LTD",
    "address": [
        "S USMAN ROAD, T. NAGAR,",
        "CHENNAI, TAMIL NADU.",
        "PHONE : 044 258636222",
        "GSTIN : 33AAAGP0685F1ZH"
    ],
    "title": "RETAIL INVOICE",
    "date": "23/03/2020",
    "time": "04:57 PM",
    "customer": "David Stores",
    "bill_no": "SR2",
    "payment_mode": "Cash",
    "dr_ref": "2",
    "items": [
        {"name": "Alternagel", "qty": 1, "amt": 200.00},
        {"name": "Bepanthen", "qty": 1, "amt": 560.00}
    ],
    "sub_total_qty": 2,
    "sub_total_amt": 760.00,
    "discount": 26.00,
    "taxes": [
        {"name": "CGST @ 14.00%", "amt": 24.36},
        {"name": "SGST @ 14.00%", "amt": 24.36},
        {"name": "CGST @ 2.50%", "amt": 14.00},
        {"name": "SGST @ 2.50%", "amt": 14.00}
    ],
    "total": 811.00,
    "cash": 811.00,
    "cash_tendered": 811.00,
    "footer": "E & O.E"
}

print("=== 80mm Printer (48 characters) ===")
print(generate_receipt(data, 48))

print("\n\n=== 58mm Printer (32 characters) ===")
print(generate_receipt(data, 32))