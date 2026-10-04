// 경로: src/module/ServiceWeb/webui/webservice/src/components/node/NodeControlPanels.tsx
import React from 'react';

interface CreateFormProps {
  facilities: { id: number; name: string }[];
  selectedFacId: number | '';
  nodeCode: string;
  nodeName: string;
  onFacilityChange: (val: number | '') => void;
  onCodeChange: (val: string) => void;
  onNameChange: (val: string) => void;
  onSubmit: () => void;
}

export const NodeCreatePanel: React.FC<CreateFormProps> = ({
  facilities, selectedFacId, nodeCode, nodeName,
  onFacilityChange, onCodeChange, onNameChange, onSubmit,
}) => (
  <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
    <h4 style={{ fontSize: 15, color: 'var(--primary)' }}>새 엣지 노드 발급</h4>

    <span className="label">소속 시설 선택</span>
    <select
      className="input"
      value={selectedFacId}
      onChange={e => onFacilityChange(e.target.value ? Number(e.target.value) : '')}
    >
      {facilities.length === 0 && <option value="">등록된 시설이 없습니다</option>}
      {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
    </select>

    <span className="label">노드 식별 코드 (Unique)</span>
    <input
      type="text"
      className="input"
      placeholder="예: NODE_FACILITY_D"
      value={nodeCode}
      onChange={e => onCodeChange(e.target.value)}
    />

    <span className="label">노드 명칭</span>
    <input
      type="text"
      className="input"
      placeholder="예: 제1시설 공조제어 노드"
      value={nodeName}
      onChange={e => onNameChange(e.target.value)}
    />

    <button onClick={onSubmit} className="btn btn-primary" style={{ marginTop: 6 }}>
      API Key 발급 및 노드 등록
    </button>
  </div>
);

interface TableProps {
  nodes: any[];
  onRefresh: () => void;
  onEdit: (node: any) => void;
  onRotate: (nodeId: number) => void;
  onDelete: (nodeId: number) => void;
}

export const NodeListTable: React.FC<TableProps> = ({ nodes, onRefresh, onEdit, onRotate, onDelete }) => (
  <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <h4 style={{ fontSize: 15 }}>등록된 시스템 노드 현황</h4>
      <button onClick={onRefresh} className="btn btn-outline btn-sm">새로고침</button>
    </div>

    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
      <thead>
        <tr style={{ borderBottom: '1px solid var(--border)', color: 'var(--text-secondary)' }}>
          <th style={{ padding: 10 }}>ID</th>
          <th style={{ padding: 10 }}>소속 시설명</th>
          <th style={{ padding: 10 }}>노드 코드</th>
          <th style={{ padding: 10 }}>명칭</th>
          <th style={{ padding: 10 }}>상태</th>
          <th style={{ padding: 10 }}>최근 신호</th>
          <th style={{ padding: 10 }}>관리</th>
        </tr>
      </thead>
      <tbody>
        {nodes.map(node => {
          const isOnline = node.status === 'ONLINE';
          return (
            <tr key={node.id} style={{ borderBottom: '1px solid var(--border)' }}>
              <td style={{ padding: 10 }}>{node.id}</td>
              <td style={{ padding: 10 }}><strong>{node.facility_name || `시설 #${node.facility_id}`}</strong></td>
              <td style={{ padding: 10, fontFamily: 'ui-monospace, monospace' }}><strong>{node.node_code}</strong></td>
              <td style={{ padding: 10 }}>{node.node_name}</td>
              <td style={{ padding: 10 }}>
                <span
                  className="chip"
                  style={{
                    background: isOnline ? 'rgba(29, 135, 90, 0.12)' : 'var(--bg)',
                    color: isOnline ? '#1d875a' : 'var(--text-secondary)',
                  }}
                >
                  {node.status}
                </span>
              </td>
              <td style={{ padding: 10, fontSize: 12, color: 'var(--text-secondary)' }}>
                {node.last_heartbeat_at ? new Date(node.last_heartbeat_at).toLocaleTimeString() : '-'}
              </td>
              <td style={{ padding: 10, display: 'flex', gap: 6 }}>
                <button onClick={() => onEdit(node)} className="btn btn-outline btn-sm">수정</button>
                <button onClick={() => onRotate(node.id)} className="btn btn-ghost btn-sm">재발급</button>
                <button onClick={() => onDelete(node.id)} className="btn btn-danger btn-sm">삭제</button>
              </td>
            </tr>
          );
        })}
        {nodes.length === 0 && (
          <tr>
            <td colSpan={7} style={{ padding: 32, textAlign: 'center', color: 'var(--text-secondary)' }}>
              등록된 노드가 없습니다.
            </td>
          </tr>
        )}
      </tbody>
    </table>
  </div>
);

export const ApiKeyModal: React.FC<{ apiKey: string | null; onClose: () => void }> = ({ apiKey, onClose }) => {
  if (!apiKey) return null;
  return (
    <div
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
      }}
    >
      <div className="card" style={{ width: 440, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <h3 style={{ color: 'var(--primary)' }}>API Key 발급 완료</h3>
        <p style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
          발급된 원문 API Key는 보안상 <strong>지금 단 한 번만</strong> 표시됩니다. 창을 닫으면 다시 조회할 수 없으므로 엣지 노드의 <code>.env</code> 파일에 복사해 두세요.
        </p>
        <div
          style={{
            padding: 12, borderRadius: 8, border: '1px dashed var(--primary)',
            background: 'var(--bg)', color: 'var(--primary)', fontFamily: 'ui-monospace, monospace', wordBreak: 'break-all',
          }}
        >
          {apiKey}
        </div>
        <button
          className="btn btn-primary"
          onClick={() => {
            navigator.clipboard.writeText(apiKey);
            onClose();
            alert('키가 클립보드에 복사되었습니다.');
          }}
        >
          복사 후 창 닫기
        </button>
      </div>
    </div>
  );
};