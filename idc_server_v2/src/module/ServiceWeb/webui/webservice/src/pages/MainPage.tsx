import React, { useState, useEffect } from 'react';
import { Monogram } from '../components/Brand';
import { apiService } from '../services/apiService';

export const MainPage: React.FC = () => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [nodes, setNodes] = useState<any[]>([]);
  const [selectedFacId, setSelectedFacId] = useState<number | ''>('');
  const [nodeCode, setNodeCode] = useState('');
  const [nodeName, setNodeName] = useState('');
  const [issuedKey, setIssuedKey] = useState<string | null>(null);

  const loadData = async () => {
    try {
      const [facRes, nodeRes] = await Promise.all([
        apiService.getNodeFacilities(),
        apiService.getNodes(),
      ]);
      const facList = facRes.data || [];
      setFacilities(facList);
      setSelectedFacId(prev => (prev === '' && facList.length > 0 ? facList[0].id : prev));
      setNodes(nodeRes.data || []);
    } catch (err) {
      console.error('노드 데이터 로드 실패:', err);
    }
  };

  useEffect(() => {
    loadData();
    const timer = setInterval(loadData, 3000);
    return () => clearInterval(timer);
  }, []);

  const handleCreateNode = async () => {
    if (!selectedFacId || !nodeCode.trim() || !nodeName.trim()) {
      return alert('모든 필드를 입력하세요.');
    }
    try {
      const res = await apiService.createNode({
        facility_id: Number(selectedFacId),
        node_code: nodeCode.trim(),
        node_name: nodeName.trim(),
      });
      setIssuedKey(res.api_key);
      setNodeCode('');
      setNodeName('');
      loadData();
    } catch (err: any) {
      alert(err.message || '생성 실패');
    }
  };

  const handleEditNode = async (node: any) => {
    const newName = window.prompt('변경할 노드 명칭을 입력하세요:', node.node_name);
    if (!newName || !newName.trim() || newName === node.node_name) return;
    try {
      await apiService.updateNode(node.id, { node_name: newName.trim() });
      loadData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleRotateKey = async (nodeId: number) => {
    if (!window.confirm('키를 재발급하면 기존 키로 연결된 통신은 즉시 차단됩니다. 진행하시겠습니까?')) return;
    try {
      const res = await apiService.rotateNodeKey(nodeId);
      setIssuedKey(res.new_api_key);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDeleteNode = async (nodeId: number) => {
    if (!window.confirm('정말 이 노드를 삭제하시겠습니까? 관련 통신과 인증이 영구 차단됩니다.')) return;
    try {
      await apiService.deleteNode(nodeId);
      loadData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16, padding: 24, boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <Monogram size={42} />
        <div>
          <h1 style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>메인 대시보드 & M2M 노드 관리</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>
            엣지 노드(FServer) API Key 발급 및 실시간 연결 상태를 관리합니다.
          </p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 16 }}>
        {/* 좌측: 노드 발급 카드 */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <h4 style={{ fontSize: 15, color: 'var(--primary)' }}>새 엣지 노드 발급</h4>

          <span className="label">소속 시설 선택</span>
          <select
            className="input"
            value={selectedFacId}
            onChange={e => setSelectedFacId(e.target.value ? Number(e.target.value) : '')}
          >
            {facilities.length === 0 && <option value="">등록된 시설이 없습니다</option>}
            {facilities.map(f => (
              <option key={f.id} value={f.id}>{f.name}</option>
            ))}
          </select>

          <span className="label">노드 식별 코드 (Unique)</span>
          <input
            type="text"
            className="input"
            placeholder="예: NODE_FACILITY_D"
            value={nodeCode}
            onChange={e => setNodeCode(e.target.value)}
          />

          <span className="label">노드 명칭</span>
          <input
            type="text"
            className="input"
            placeholder="예: 제1시설 공조제어 노드"
            value={nodeName}
            onChange={e => setNodeName(e.target.value)}
          />

          <button onClick={handleCreateNode} className="btn btn-primary" style={{ marginTop: 6 }}>
            API Key 발급 및 노드 등록
          </button>
        </div>

        {/* 우측: 노드 현황 테이블 */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h4 style={{ fontSize: 15 }}>등록된 시스템 노드 현황</h4>
            <button onClick={loadData} className="btn btn-outline btn-sm">새로고침</button>
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
                    <td style={{ padding: 10, fontFamily: 'monospace' }}><strong>{node.node_code}</strong></td>
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
                      <button onClick={() => handleEditNode(node)} className="btn btn-outline btn-sm">수정</button>
                      <button onClick={() => handleRotateKey(node.id)} className="btn btn-ghost btn-sm">재발급</button>
                      <button onClick={() => handleDeleteNode(node.id)} className="btn btn-danger btn-sm">삭제</button>
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
      </div>

      {/* API Key 1회성 표시 모달 */}
      {issuedKey && (
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
                background: 'var(--bg)', color: 'var(--primary)', fontFamily: 'monospace', wordBreak: 'break-all',
              }}
            >
              {issuedKey}
            </div>
            <button
              className="btn btn-primary"
              onClick={() => {
                navigator.clipboard.writeText(issuedKey);
                setIssuedKey(null);
                alert('키가 클립보드에 복사되었습니다.');
              }}
            >
              복사 후 창 닫기
            </button>
          </div>
        </div>
      )}
    </div>
  );
};