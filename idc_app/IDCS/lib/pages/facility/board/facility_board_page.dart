// ===============================================================
// 경로: lib/pages/facility/board/facility_board_page.dart
// 명세: 시설 소요 기록 페이지 (단일 시설 포스트 조회)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/components/cross_compontents/board/shared_board_compontents.dart';
import 'package:idcs/services/board/board_api_service.dart';

class FacilityBoardPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityBoardPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityBoardPage> createState() => _FacilityBoardPageState();
}

class _FacilityBoardPageState extends State<FacilityBoardPage> {
  final TextEditingController _searchController = TextEditingController();
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

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final result = await BoardApiService.fetchFacilityPosts(
        facilityId: widget.facilityId,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSearch() {
    _currentPage = 1;
    _fetchPosts();
  }

  void _handlePostTapped(int postId) {
    context.push('/post_detail/${widget.userId}/$postId').then((_) => _fetchPosts());
  }

  void _handleCreatePost() {
    context.push('/post_create/${widget.userId}/${widget.facilityId}').then((_) => _fetchPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('소요 기록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoardHeaderBox(
              title: '게시글 검색',
              searchController: _searchController,
              selectedSearchType: _selectedSearchType,
              onSearchTypeChanged: (val) {
                if (val != null) setState(() => _selectedSearchType = val);
              },
              onSearch: _handleSearch,
              onCreatePost: _handleCreatePost,
            ),
            const SizedBox(height: 16),
            BoardListAndPagingBox(
              posts: _posts,
              isLoading: _isLoading,
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _fetchPosts();
              },
              onPostTapped: _handlePostTapped,
            ),
          ],
        ),
      ),
    );
  }
}