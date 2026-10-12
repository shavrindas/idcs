// ===============================================================
// 경로: lib/pages/facility/board/facility_board_page.dart
// 명세: 시설 소요 기록 페이지 (단일 시설 포스트 조회)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/models/post_model.dart';
import 'package:idcs/components/cross_compontents/board/shared_board_compontents.dart';
import 'package:idcs/services/board/board_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

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
        AppToast.error(context, describeApiError(context, e));
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
      appBar: AppBar(title: Text(context.l10n.boardPageTitle)),
      // 새 글은 목록 어디에 있든 닿을 수 있어야 해서 떠 있는 버튼으로 뺐다.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreatePost,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(context.l10n.boardNewPost),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoardSearchBox(
              searchController: _searchController,
              selectedSearchType: _selectedSearchType,
              onSearchTypeChanged: (val) {
                setState(() => _selectedSearchType = val);
                _handleSearch();
              },
              onSearch: _handleSearch,
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