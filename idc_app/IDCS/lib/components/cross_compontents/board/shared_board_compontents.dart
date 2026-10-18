// ===============================================================
// 경로: lib/components/cross_compontents/board/shared_board_compontents.dart
// 명세: 통합/시설 게시판 공통 UI 컴포넌트 (검색, 필터, 리스트, 페이징)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/theme/app_theme.dart';

/// 검색어와 검색 대상을 고르는 박스.
///
/// 드롭다운·입력창·버튼을 한 줄에 욱여넣으면 각 칸이 좁아져 무엇을 누르는지
/// 알기 어렵다. 입력창이 한 줄을 다 쓰고, 대상은 그 아래 칩으로 편다 —
/// 고를 수 있는 것이 한눈에 보이고 손가락도 편하다.
class BoardSearchBox extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedSearchType;
  final ValueChanged<String> onSearchTypeChanged;
  final VoidCallback onSearch;

  const BoardSearchBox({
    super.key,
    required this.searchController,
    required this.selectedSearchType,
    required this.onSearchTypeChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final types = <String, String>{
      'all': context.l10n.boardSearchAll,
      'title': context.l10n.boardTitle,
      'creator': context.l10n.boardAuthor,
      'content': context.l10n.boardBody,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: context.l10n.boardSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              // The keyboard's search key runs the query; a separate button
              // beside the field only ate width.
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: context.l10n.boardSearchClear,
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearch();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: types.entries.map((e) {
              final selected = selectedSearchType == e.key;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => onSearchTypeChanged(e.key),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.onPrimary : colors.textPrimary,
                ),
                selectedColor: colors.primary,
                backgroundColor: colors.background,
                side: BorderSide(color: selected ? colors.primary : colors.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 게시글 목록과 페이지 이동.
///
/// 예전에는 목록이 400px로 고정돼 있어, 글이 하나뿐이어도 빈 상자가 그만큼
/// 남고 그 안에서 또 스크롤이 생겼다. 이제 내용만큼만 차지하고 스크롤은
/// 페이지 하나만 갖는다.
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
    final colors = context.colors;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 28, color: colors.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(context.l10n.boardEmpty, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: colors.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < posts.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: colors.outline),
                _PostRow(post: posts[i], onTap: () => onPostTapped(posts[i].postId)),
              ],
            ],
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          _Paging(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
        ],
      ],
    );
  }
}

class _PostRow extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (post.facilityName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.facilityName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          post.creatorName.isEmpty ? context.l10n.noName : post.creatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// 페이지 이동.
///
/// 번호를 모두 늘어놓으면 손가락으로 집기엔 너무 작고, 페이지가 많아지면
/// 가로로 넘쳐 또 스크롤이 생긴다. 지금 위치만 보여주고 앞뒤로 움직인다.
class _Paging extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const _Paging({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget button(IconData icon, String tooltip, int? target) {
      return IconButton(
        tooltip: tooltip,
        onPressed: target == null ? null : () => onPageChanged(target),
        icon: Icon(icon, size: 20),
        color: colors.textPrimary,
        disabledColor: colors.textSecondary.withValues(alpha: 0.35),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(Icons.keyboard_double_arrow_left_rounded, context.l10n.pageFirst,
            currentPage > 1 ? 1 : null),
        button(Icons.chevron_left_rounded, context.l10n.pagePrev,
            currentPage > 1 ? currentPage - 1 : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            context.l10n.pageOf(currentPage, totalPages),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        button(Icons.chevron_right_rounded, context.l10n.pageNext,
            currentPage < totalPages ? currentPage + 1 : null),
        button(Icons.keyboard_double_arrow_right_rounded, context.l10n.pageLast,
            currentPage < totalPages ? totalPages : null),
      ],
    );
  }
}
