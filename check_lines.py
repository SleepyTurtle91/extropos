files = [
    'lib/screens/setup_screen.dart',
    'lib/screens/modern_reports_dashboard.dart',
    'lib/screens/receipt_designer_screen.dart',
    'lib/screens/items_management_screen.dart'
]

for f in files:
    with open(f, 'r', encoding='utf-8', errors='ignore') as file:
        count = len(file.readlines())
    name = f.split('/')[-1]
    status = 'COMPLIANT' if 500 <= count <= 1000 else 'VIOLATION'
    print(f'{name}: {count} lines [{status}]')
