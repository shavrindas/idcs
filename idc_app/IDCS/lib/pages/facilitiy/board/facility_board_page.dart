// ===============================================================
// 경로: lib/pages/facilitiy/board/facility_board_page.dart
// 명세: 시설 소요 기록 페이지 (단일 시설 포스트 조회)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/models/post_model.dart'; // PostModel 임포트
import 'package:idcs/components/cross_compontents/board/shared_board_compontents.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:idcs/main.dart'; // AppConfig, AuthService

class FacilityBoardPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityBoardPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityBoardPage> createState() => _FacilityBoardPageState();
}

class _FacilityBoardPageState extends State<FacilityBoardPage> {
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/board/facility/${widget.facilityId}?user_id=${widget.userId}&page=$_currentPage&limit=$_limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _posts = (decoded['data'] as List).map((p) => PostModel.fromJson(p)).toList();
          _totalPages = decoded['meta']['total_pages'] ?? 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('시설 게시글을 불러오는데 실패했습니다: $e')));
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

  void _handleCreatePost() {
    context.push('/post_create/${widget.userId}/${widget.facilityId}').then((_) => _fetchPosts());
  }

  void _handleSearch() {
    _currentPage = 1;
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('시설 ${widget.facilityId} 소요 기록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1 (새 글 작성 콜백 포함)
            BoardHeaderBox(
              title: '게시글 검색',
              searchController: _searchController,
              onSearch: _handleSearch,
              onCreatePost: _handleCreatePost,
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