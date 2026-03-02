part of 'horizon_inventory_grid_screen.dart';

/// Extension containing pagination controls
extension HorizonInventoryPagination on _HorizonInventoryGridScreenState {
  /// Build pagination controls
  Widget buildPaginationControls() {
    final totalPages = (_totalProducts / _pageSize).ceil();
    final startItem = _currentPage * _pageSize + 1;
    final endItem = (_currentPage + 1) * _pageSize;
    final actualEnd = endItem > _totalProducts ? _totalProducts : endItem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem to $actualEnd of $_totalProducts products',
          style: const TextStyle(
            fontSize: 13,
            color: HorizonColors.textSecondary,
          ),
        ),
        Row(
          children: [
            HorizonButton(
              text: 'Previous',
              type: HorizonButtonType.secondary,
              onPressed: _currentPage > 0 ? () {
                setState(() {
                  _currentPage--;
                });
                loadProducts();
              } : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: HorizonColors.surfaceGrey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            HorizonButton(
              text: 'Next',
              type: HorizonButtonType.secondary,
              onPressed: _hasMorePages ? () {
                setState(() {
                  _currentPage++;
                });
                loadProducts();
              } : null,
            ),
          ],
        ),
      ],
    );
  }
}
