// ===============================================================
// 경로: lib/components/cross_compontents/board/shared_board_compontents.dart
// 명세: 통합/시설 게시판 공통 UI 컴포넌트 (검색, 필터, 리스트, 페이징)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/theme/app_theme.dart';

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (onCreatePost != null)
                ElevatedButton.icon(
                  onPressed: onCreatePost,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('새 글 작성'),
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
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSearchType,
                    icon: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('전체')),
                      DropdownMenuItem(value: 'title', child: Text('제목')),
                      DropdownMenuItem(value: 'creator', child: Text('작성자')),
                      DropdownMenuItem(value: 'content', child: Text('내용')),
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
                  decoration: const InputDecoration(
                    hintText: '검색어를 입력하세요',
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
                  child: const Text('검색'),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
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
                ? const Center(
                    child: Text('등록된 포스트가 없습니다.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.outline),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '[${post.facilityName}] 작성자: ${post.creatorName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                  onTap: () => onPostTapped(post.postId),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Box #3: 페이징 영역
          _buildPagingControl(),
        ],
      ),
    );
  }

  Widget _buildPagingControl() {
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
              tooltip: '첫 페이지',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            ),
            IconButton(
              tooltip: '이전 페이지',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textSecondary),
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
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 4),
            IconButton(
              tooltip: '다음 페이지',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: endPage < safeTotalPages ? () => onPageChanged(endPage + 1) : null,
            ),
            IconButton(
              tooltip: '마지막 페이지',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
              icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: currentPage < safeTotalPages ? () => onPageChanged(safeTotalPages) : null,
            ),
          ],
        ),
      ),
    );
  }
}
