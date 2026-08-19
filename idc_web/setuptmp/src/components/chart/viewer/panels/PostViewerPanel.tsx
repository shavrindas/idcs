import React from 'react';

interface Props {
  selectedPostIds: number[];
  posts: any[];
  selectedGroupId: number | '';
  onHidePost: (id: number) => void;
}

export const PostViewerPanel: React.FC<Props> = ({ selectedPostIds, posts, selectedGroupId, onHidePost }) => (
  <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', flexDirection: 'column', padding: 10, backgroundColor: '#1e1e1e', overflowY: 'auto' }}>
    <h4 style={{ margin: '0 0 10px 0', textAlign: 'center' }}>소요기록 Viewer</h4>
    {selectedPostIds.length > 0 ? (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 15 }}>
        {selectedPostIds.map(postId => {
          const post = posts.find(p => p.id === postId);
          if (!post) return null;
          return (
            <div key={postId} style={{ color: '#fff', display: 'flex', flexDirection: 'column', borderBottom: '1px solid #444', paddingBottom: 10 }}>
              <h5 style={{ color: '#ff4d4f', margin: '0 0 5px 0' }}>{post.title}</h5>
              <p style={{ fontSize: 12, color: '#aaa', margin: '0 0 10px 0' }}>{post.content}</p>
              <button 
                onClick={() => onHidePost(postId)} disabled={!selectedGroupId}
                style={{ alignSelf: 'flex-end', padding: '4px 8px', backgroundColor: '#ff4d4f', color: '#fff', border: 'none', cursor: 'pointer', borderRadius: 4, fontSize: 11 }}
              >
                이 그룹에서 숨기기
              </button>
            </div>
          );
        })}
      </div>
    ) : (
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#555' }}>
        차트에서 붉은 영역(소요기록)을 클릭하세요.
      </div>
    )}
  </div>
);