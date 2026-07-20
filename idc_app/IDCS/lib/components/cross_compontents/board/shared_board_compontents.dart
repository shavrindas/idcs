// ===============================================================
// 경로: lib/components/cross_compontents/board/shared_board_compontents.dart
// 명세: 통합/시설 게시판 공통 UI 컴포넌트 (검색, 필터, 리스트, 페이징)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/models/post_model.dart';
/// Box #1: 보드 헤더 박스 (검색 및 필터)
class BoardHeaderBox extends StatelessWidget {
  final String title;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback? onCreatePost; // 시설 게시판용 새 글 작성 버튼

  const BoardHeaderBox({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearch,
    this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              if (onCreatePost != null)
                ElevatedButton.icon(
                  onPressed: onCreatePost,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('새 글 작성'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 필터 드롭다운 (예시)
              DropdownButton<String>(
                value: '전체',
                items: <String>['전체', '제목', '작성자', '내용'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) {
                  // TODO: 필터 상태 관리
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: '검색어를 입력하세요',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSearch,
                child: const Text('검색'),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box #2: 리스트 영역
          Container(
            height: 400, // 리스트 고정 높이 또는 Expanded 사용 가능
            padding: const EdgeInsets.all(8.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? const Center(child: Text('등록된 포스트가 없습니다.'))
                : ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('[${post.facilityName}] 작성자: ${post.creatorName}'),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  onTap: () => onPostTapped(post.postId),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),

          // Box #3: 페이징 영역
          _buildPagingControl(),
        ],
      ),
    );
  }

  Widget _buildPagingControl() {
    final int blockSize = 5; //[cite: 6]
    final int currentBlock = ((currentPage - 1) ~/ blockSize); //[cite: 6]
    final int startPage = currentBlock * blockSize + 1; //[cite: 6]
    final int endPage = (startPage + blockSize - 1 > totalPages) ? totalPages : startPage + blockSize - 1; //[cite: 6]
    final safeTotalPages = totalPages > 0 ? totalPages : 1; //[cite: 6]

    return Padding(
      padding: const EdgeInsets.all(8.0), //[cite: 6]
      // 💡 SingleChildScrollView로 감싸서 오버플로우 방지
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, //[cite: 6]
          children: [
            IconButton(
              constraints: const BoxConstraints(), // 여백 축소
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.keyboard_double_arrow_left), //[cite: 6]
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null, //[cite: 6]
            ),
            IconButton(
              constraints: const BoxConstraints(), // 여백 축소
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.chevron_left), //[cite: 6]
              onPressed: startPage > 1 ? () => onPageChanged(startPage - 1) : null, //[cite: 6]
            ),
            const SizedBox(width: 4),

            ...List.generate(endPage - startPage + 1, (index) { //[cite: 6]
              final pageNum = startPage + index; //[cite: 6]
              return InkWell(
                onTap: () => onPageChanged(pageNum), //[cite: 6]
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2), // 4 -> 2로 간격 감소
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // 간격 감소
                  decoration: BoxDecoration(
                    color: currentPage == pageNum ? Colors.blueAccent : Colors.transparent, //[cite: 6]
                    borderRadius: BorderRadius.circular(4), //[cite: 6]
                  ),
                  child: Text(
                    '$pageNum', //[cite: 6]
                    style: TextStyle(
                      color: currentPage == pageNum ? Colors.white : Colors.black, //[cite: 6]
                      fontWeight: currentPage == pageNum ? FontWeight.bold : FontWeight.normal, //[cite: 6]
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(), // 여백 축소
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.chevron_right), //[cite: 6]
              onPressed: endPage < safeTotalPages ? () => onPageChanged(endPage + 1) : null, //[cite: 6]
            ),
            IconButton(
              constraints: const BoxConstraints(), // 여백 축소
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.keyboard_double_arrow_right), //[cite: 6]
              onPressed: currentPage < safeTotalPages ? () => onPageChanged(safeTotalPages) : null, //[cite: 6]
            ),
          ],
        ),
      ),
    );
  }
}