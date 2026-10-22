// 경로: src/module/ServiceWeb/webui/webservice/src/pages/MainPage.tsx
import React, { useState, useEffect } from 'react';
import { Monogram } from '../components/Brand';
import { apiService } from '../services/apiService';
import { NodeCreatePanel, NodeListTable, ApiKeyModal } from '../components/node/NodeControlPanels';
import type { SessionUser } from '../types';

export const MainPage: React.FC<{ user: SessionUser }> = ({ user }) => {
  const [facilities, setFacilities] = useState<any[]>([]);
  const [nodes, setNodes] = useState<any[]>([]);
  const [selectedFacId, setSelectedFacId] = useState<number | ''>('');
  const [nodeCode, setNodeCode] = useState('');
  const [nodeName, setNodeName] = useState('');
  const [issuedKey, setIssuedKey] = useState<string | null>(null);
  const [syncOk, setSyncOk] = useState<boolean>(true);
  const [lastSync, setLastSync] = useState<string>('-');

  const loadData = async () => {
    try {
      const [facRes, nodeRes] = await Promise.all([
        apiService.getNodeFacilities(user.id),
        apiService.getNodes(user.id),
      ]);
      const facList = facRes.data || [];
      setFacilities(facList);
      setSelectedFacId(prev => (prev === '' && facList.length > 0 ? facList[0].id : prev));
      setNodes(nodeRes.data || []);
      setSyncOk(true);
      setLastSync(new Date().toLocaleTimeString());
    } catch (err) {
      console.error('노드 데이터 로드 실패:', err);
      setSyncOk(false);
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

  const onlineCount = nodes.filter(n => n.status === 'ONLINE').length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16, padding: 24, boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Monogram size={42} />
          <div>
            <h1 style={{ fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>메인 대시보드 & M2M 노드 관리</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 13 }}>
              엣지 노드(FServer) API Key 발급 및 3초 주기 실시간 연결 상태를 모니터링합니다.
            </p>
          </div>
        </div>

        <div className="card" style={{ padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ fontSize: 13 }}>
            백엔드 상태:{' '}
            <strong style={{ color: syncOk ? '#1d875a' : 'var(--error)' }}>
              {syncOk ? '정상 연결됨' : '연결 끊김'}
            </strong>{' '}
            <span style={{ color: 'var(--text-secondary)', fontSize: 12 }}>({lastSync})</span>
          </span>
          <span className="chip">온라인 노드: {onlineCount} / {nodes.length}</span>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 16 }}>
        <NodeCreatePanel
          facilities={facilities}
          selectedFacId={selectedFacId}
          nodeCode={nodeCode}
          nodeName={nodeName}
          onFacilityChange={setSelectedFacId}
          onCodeChange={setNodeCode}
          onNameChange={setNodeName}
          onSubmit={handleCreateNode}
        />
        <NodeListTable
          nodes={nodes}
          onRefresh={loadData}
          onEdit={handleEditNode}
          onRotate={handleRotateKey}
          onDelete={handleDeleteNode}
        />
      </div>

      <ApiKeyModal apiKey={issuedKey} onClose={() => setIssuedKey(null)} />
    </div>
  );
};