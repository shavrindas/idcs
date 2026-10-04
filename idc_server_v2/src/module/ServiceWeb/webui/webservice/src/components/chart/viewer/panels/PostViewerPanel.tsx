import React from 'react';

interface Props {
  selectedPostIds: number[];
  posts: any[];
  selectedGroupId: number | '';
  onHidePost: (id: number) => void;
}

export const PostViewerPanel: React.FC<Props> = ({ selectedPostIds, posts, selectedGroupId, onHidePost }) => (
  <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
    <h4 style={{ margin: '0 0 10px 0', textAlign: 'center', fontSize: 14 }}>소요기록 Viewer</h4>
    {selectedPostIds.length > 0 ? (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 15 }}>
        {selectedPostIds.map(postId => {
          const post = posts.find(p => p.id === postId);
          if (!post) return null;
          return (
            <div key={postId} style={{ display: 'flex', flexDirection: 'column', borderBottom: '1px solid var(--border)', paddingBottom: 10 }}>
              <h5 style={{ color: 'var(--error)', margin: '0 0 5px 0', fontSize: 13 }}>{post.title}</h5>
              <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '0 0 10px 0' }}>{post.content}</p>
              <button
                onClick={() => onHidePost(postId)} disabled={!selectedGroupId}
                className="btn btn-danger btn-sm"
                style={{ alignSelf: 'flex-end' }}
              >
                이 그룹에서 숨기기
              </button>
            </div>
          );
        })}
      </div>
    ) : (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)', fontSize: 13, textAlign: 'center' }}>
        차트에서 붉은 영역(소요기록)을 클릭하세요.
      </div>
    )}
  </div>
);
