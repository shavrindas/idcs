// ===============================================================
// 경로: lib/pages/indices/total_board_page.dart
// 명세: 통합 소요 기록 페이지 (모든 시설 포스트 조회)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/components/cross_compontents/board/shared_board_compontents.dart';
import 'package:idcs/services/board/board_api_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class TotalBoardPage extends StatefulWidget {
  final String userId;
  const TotalBoardPage({super.key, required this.userId});

  @override
  State<TotalBoardPage> createState() => _TotalBoardPageState();
}

class _TotalBoardPageState extends State<TotalBoardPage> {
  final TextEditingController _searchController = TextEditingController();

  // 📌 1. 검색 필터 선택 상태값 추가
  String _selectedSearchType = 'all';

  List<PostModel> _posts = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 📌 2. BoardApiService 적용 및 검색 파라미터 전달
  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final result = await BoardApiService.fetchIntegratedPosts(
        userId: widget.userId,
        page: _currentPage,
        limit: _limit,
        searchType: _selectedSearchType,
        keyword: _searchController.text,
      );

      if (mounted) {
        setState(() {
          _posts = result['posts'];
          _totalPages = result['totalPages'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePageChange(int newPage) {
    setState(() => _currentPage = newPage);
    _fetchPosts();
  }

  void _handlePostTapped(int postId) {
    context.push('/post_detail/${widget.userId}/$postId').then((_) => _fetchPosts());
  }

  void _handleSearch() {
    _currentPage = 1;
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.totalBoardTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📌 3. 필수 전달 인자 누락 에러 수정 부분
            BoardHeaderBox(
              title: context.l10n.totalBoardSearch,
              searchController: _searchController,
              selectedSearchType: _selectedSearchType,
              onSearchTypeChanged: (val) {
                if (val != null) setState(() => _selectedSearchType = val);
              },
              onSearch: _handleSearch,
            ),
            const SizedBox(height: 16),

            // Box #2 & #3
            BoardListAndPagingBox(
              posts: _posts,
              isLoading: _isLoading,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: _handlePageChange,
              onPostTapped: _handlePostTapped,
            ),
          ],
        ),
      ),
    );
  }
}