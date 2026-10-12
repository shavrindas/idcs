// ===============================================================
// 경로: lib/components/cross_compontents/board/shared_board_compontents.dart
// 명세: 통합/시설 게시판 공통 UI 컴포넌트 (검색, 필터, 리스트, 페이징)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: 보드 헤더 박스 (검색 및 필터)
class BoardHeaderBox extends StatelessWidget {
  final String title;
  final TextEditingController searchController;
  final String selectedSearchType;
  final ValueChanged<String?> onSearchTypeChanged;
  final VoidCallback onSearch;
  final VoidCallback? onCreatePost;

  const BoardHeaderBox({
    super.key,
    required this.title,
    required this.searchController,
    required this.selectedSearchType,
    required this.onSearchTypeChanged,
    required this.onSearch,
    this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              if (onCreatePost != null)
                ElevatedButton.icon(
                  onPressed: onCreatePost,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.l10n.boardNewPost),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSearchType,
                    icon: Icon(Icons.expand_more_rounded, size: 20, color: context.colors.textSecondary),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(context.l10n.boardSearchAll)),
                      DropdownMenuItem(value: 'title', child: Text(context.l10n.boardTitle)),
                      DropdownMenuItem(value: 'creator', child: Text(context.l10n.boardAuthor)),
                      DropdownMenuItem(value: 'content', child: Text(context.l10n.boardBody)),
                    ],
                    onChanged: onSearchTypeChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: context.l10n.boardSearchHint,
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onSearch,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
                  child: Text(context.l10n.actionSearch),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Box #2 & #3: 보드 리스트 및 페이징 박스
class BoardListAndPagingBox extends StatelessWidget {
  final List<PostModel> posts;
  final bool isLoading;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final Function(int) onPostTapped;

  const BoardListAndPagingBox({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onPostTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.colors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box #2: 리스트 영역
          SizedBox(
            height: 400,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? Center(
                    child: Text(context.l10n.boardEmpty, style: TextStyle(color: context.colors.textSecondary)),
                  )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: posts.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: context.colors.outline),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                  ),
                  subtitle: Text(
                    context.l10n.boardPostMeta(
                      post.facilityName,
                      // The model leaves this empty when the server had no author.
                      post.creatorName.isEmpty ? context.l10n.noName : post.creatorName,
                    ),
                    style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, size: 20, color: context.colors.textSecondary),
                  onTap: () => onPostTapped(post.postId),
                );
              },
            ),
          ),
          Divider(height: 1, color: context.colors.outline),

          // Box #3: 페이징 영역
          _buildPagingControl(context),
        ],
      ),
    );
  }

  Widget _buildPagingControl(BuildContext context) {
    final int blockSize = 5;
    final int currentBlock = ((currentPage - 1) ~/ blockSize);
    final int startPage = currentBlock * blockSize + 1;
    final int endPage = (startPage + blockSize - 1 > totalPages) ? totalPages : startPage + blockSize - 1;
    final safeTotalPages = totalPages > 0 ? totalPages : 1;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: context.l10n.pageFirst,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.keyboard_double_arrow_left_rounded, size: 18, color: context.colors.textSecondary),
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            ),
            IconButton(
              tooltip: context.l10n.pagePrev,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.chevron_left_rounded, size: 18, color: context.colors.textSecondary),
              onPressed: startPage > 1 ? () => onPageChanged(startPage - 1) : null,
            ),
            const SizedBox(width: 4),

            ...List.generate(endPage - startPage + 1, (index) {
              final pageNum = startPage + index;
              final bool isActive = currentPage == pageNum;
              return InkWell(
                onTap: () => onPageChanged(pageNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? context.colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isActive ? context.colors.onPrimary : context.colors.textPrimary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 4),
            IconButton(
              tooltip: context.l10n.pageNext,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textSecondary),
              onPressed: endPage < safeTotalPages ? () => onPageChanged(endPage + 1) : null,
            ),
            IconButton(
              tooltip: context.l10n.pageLast,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: context.colors.textSecondary),
              onPressed: currentPage < safeTotalPages ? () => onPageChanged(safeTotalPages) : null,
            ),
          ],
        ),
      ),
    );
  }
}
