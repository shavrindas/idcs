// ===============================================================
// 경로: lib/pages/indices/total_board_page.dart
// 명세: 통합 소요 기록 페이지 (모든 시설 포스트 조회)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/components/cross_compontents/board/shared_board_compontents.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:idcs/main.dart'; // AppConfig, AuthService

class TotalBoardPage extends StatefulWidget {
  final String userId;
  const TotalBoardPage({super.key, required this.userId});

  @override
  State<TotalBoardPage> createState() => _TotalBoardPageState();
}

class _TotalBoardPageState extends State<TotalBoardPage> {
  final TextEditingController _searchController = TextEditingController();

  List<PostModel> _posts = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10; // 테스트를 위해 10개로 설정, 필요시 30으로 변경

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

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/board/integrated?user_id=${widget.userId}&page=$_currentPage&limit=$_limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _posts = (decoded['data'] as List).map((p) => PostModel.fromJson(p)).toList();
          _totalPages = decoded['meta']['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('통합 게시글을 불러오는데 실패했습니다: $e')));
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
    // TODO: 백엔드 검색 API 연동 로직
    _currentPage = 1;
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통합 소요 기록 (관리자)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1
            BoardHeaderBox(
              title: '통합 검색 및 필터',
              searchController: _searchController,
              onSearch: _handleSearch,
              // 통합 보드에서는 '새 글 작성' 기능이 일반적으로 없으므로 null 전달
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