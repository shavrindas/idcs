// src/pages/ChartViewerPage.tsx
import React, { useState, useEffect } from 'react';
import { EChartsViewer } from '../components/chart/EChartsViewer';
import type { ChartMode, ChartScale } from '../constants/chartConfig';
import { apiService } from '../services/apiService';
import type { Role, ChartGroup } from '../types';

// 현재 시간을 YYYY-MM-DDTHH:mm 포맷으로 반환하는 헬퍼 함수
const getLocalDatetimeString = (date: Date) => {
  const offset = date.getTimezoneOffset() * 60000;
  return (new Date(date.getTime() - offset)).toISOString().slice(0, 16);
};

export const ChartViewerPage: React.FC = () => {
  const [mode, setMode] = useState<ChartMode>('DEFAULT');
  const [scale, setScale] = useState<ChartScale>('1m');
  
  // Top Tool Bar (RQ-6.1) 일자 검색 상태
  const [targetDate, setTargetDate] = useState<string>(getLocalDatetimeString(new Date()));
  
  const [facilities, setFacilities] = useState<any[]>([]);
  const [rooms, setRooms] = useState<any[]>([]);
  const [groups, setGroups] = useState<ChartGroup[]>([]);
  const [allRoles, setAllRoles] = useState<Role[]>([]);

  const [selectedFacility, setSelectedFacility] = useState<number | ''>('');
  const [selectedRoom, setSelectedRoom] = useState<number | ''>('');
  const [selectedGroupId, setSelectedGroupId] = useState<number | ''>('');
  const [checkedRoles, setCheckedRoles] = useState<number[]>([]);
  
  // EChartsViewer로 넘겨줄 데이터셋 상태
  const [chartDataSets, setChartDataSets] = useState<any[]>([]);

  useEffect(() => {
    apiService.getFacilities().then(res => setFacilities(res.facilities || []));
  }, []);

  useEffect(() => {
    if (selectedFacility) {
      apiService.getRooms(Number(selectedFacility)).then(res => setRooms(res.rooms || []));
      setSelectedRoom('');
      setGroups([]);
      setAllRoles([]);
      setSelectedGroupId('');
      setCheckedRoles([]);
      setChartDataSets([]);
    }
  }, [selectedFacility]);

  useEffect(() => {
    if (selectedFacility && selectedRoom) {
      apiService.getChartGroups(Number(selectedFacility), Number(selectedRoom))
        .then(res => setGroups(res.groups || [])); 
      apiService.getPointRoles(Number(selectedFacility), Number(selectedRoom))
        .then(res => setAllRoles(res.roles || []));
      
      setSelectedGroupId('');
      setCheckedRoles([]);
      setChartDataSets([]);
    }
  }, [selectedRoom, selectedFacility]);

  useEffect(() => {
    if (selectedGroupId) {
      const group = groups.find(g => g.group_id === Number(selectedGroupId));
      if (group && group.role_ids) {
        const validRoles = group.role_ids.filter(id => id !== null);
        setCheckedRoles(validRoles);
      }
    } else {
      setCheckedRoles([]);
      setChartDataSets([]);
    }
  }, [selectedGroupId, groups]);

  // 실제 데이터 호출 로직
  useEffect(() => {
    if (selectedFacility && selectedRoom && checkedRoles.length > 0 && targetDate) {
      const endIso = new Date(targetDate).toISOString();
      apiService.getHistoricalData(Number(selectedFacility), Number(selectedRoom), scale, endIso, checkedRoles)
        .then(res => {
          setChartDataSets(res.data?.datasets || []);
        })
        .catch(err => console.error("차트 데이터 호출 오류:", err));
    } else {
      setChartDataSets([]);
    }
  }, [selectedFacility, selectedRoom, scale, targetDate, checkedRoles]);

  const handleModeToggle = () => {
    setMode(prev => {
      const nextMode = prev === 'DEFAULT' ? 'EXTENT' : 'DEFAULT';
      if (nextMode === 'EXTENT' && checkedRoles.length > 1) {
        setCheckedRoles([checkedRoles[0]]);
      }
      return nextMode;
    });
  };

  const handleRoleToggle = (roleId: number) => {
    setCheckedRoles(prev => {
      if (prev.includes(roleId)) {
        return prev.filter(id => id !== roleId);
      } else {
        if (mode === 'EXTENT') return [roleId];
        return [...prev, roleId];
      }
    });
  };

  // 체크박스 렌더링을 위해 현재 선택된 그룹의 전체 Role 추출 (버그 수정됨)
  const currentGroup = groups.find(g => g.group_id === Number(selectedGroupId));
  const groupRoleIds = currentGroup && currentGroup.role_ids ? currentGroup.role_ids.filter(id => id !== null) : [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: 10, boxSizing: 'border-box' }}>
      
      <div style={{ display: 'flex', flex: 1, gap: 10, minHeight: 0 }}>
        {/* ================= 왼쪽: 차트 영역 ================= */}
        <div style={{ flex: 2, border: '2px solid #2196f3', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: '#9c27b0', fontWeight: 'bold' }}>Top Tool Bar (RQ-6.1)</span>
            <input 
              type="datetime-local" 
              value={targetDate}
              onChange={(e) => setTargetDate(e.target.value)}
              title="RQ-6.3 일자 검색" 
              style={{ padding: 4 }} 
            />
          </div>
          
          {/* Main Chart 영역 (비율을 3으로 조정하여 넓게) */}
          <div style={{ border: '2px solid #ffffff', flex: 3, display: 'flex', flexDirection: 'column', backgroundColor: '#1e1e1e' }}>
            <EChartsViewer datasets={chartDataSets} />
          </div>
          
          <div style={{ border: '2px solid #9c27b0', padding: 10, textAlign: 'center', color: '#9c27b0', fontWeight: 'bold' }}>
            Lower Tool Bar
          </div>

          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#1e1e1e' }}>
            <span style={{ color: '#aaa' }}>sub chart (*bool 용도 - 임시 공간)</span>
          </div>
        </div>

        {/* ================= 오른쪽: 패널 영역 ================= */}
        <div style={{ flex: 1, border: '2px solid #e91e63', display: 'flex', flexDirection: 'column', padding: 10, gap: 10 }}>
          <div style={{ border: '2px solid #ffffff', padding: 15, textAlign: 'center', fontWeight: 'bold' }}>
            [임시 격리] 검색창 모듈
          </div>
          
          <div style={{ border: '2px solid #ffffff', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <h4 style={{ margin: 0, textAlign: 'center' }}>메인 조작 패널 1 (스코핑)</h4>
            
            <button onClick={handleModeToggle} style={{ padding: 8, cursor: 'pointer' }}>
              현재 모드: {mode} (토글)
            </button>

            <select value={scale} onChange={(e) => setScale(e.target.value as ChartScale)} style={{ padding: 8 }}>
              <option value="10s">10초 단위</option>
              <option value="1m">1분 단위</option>
              <option value="5m">5분 단위</option>
              <option value="1h">1시간 단위</option>
            </select>

            <select value={selectedFacility} onChange={(e) => setSelectedFacility(e.target.value ? Number(e.target.value) : '')} style={{ padding: 8 }}>
              <option value="">-- 시설 선택 --</option>
              {facilities.map(fac => (
                <option key={fac.id} value={fac.id}>{fac.name}</option>
              ))}
            </select>

            <select value={selectedRoom} onChange={(e) => setSelectedRoom(e.target.value ? Number(e.target.value) : '')} disabled={!selectedFacility} style={{ padding: 8 }}>
              <option value="">-- 호실 선택 --</option>
              {rooms.map(room => (
                <option key={room.id} value={room.id}>{room.name}</option>
              ))}
            </select>
          </div>
          
          <div style={{ border: '2px solid #ffffff', flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', textAlign: 'center', fontWeight: 'bold' }}>
            소요기록 viewer
          </div>
        </div>
      </div>

      {/* ================= 하단: 메인 조작 패널 2 ================= */}
      <div style={{ border: '2px solid #4caf50', padding: 15, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <h4 style={{ margin: 0, textAlign: 'center', color: '#4caf50' }}>메인 조작 패널 2 (맵핑 그룹 활성화)</h4>
        
        <div style={{ display: 'flex', gap: 15, alignItems: 'center', justifyContent: 'center' }}>
          <select 
            value={selectedGroupId} 
            onChange={(e) => setSelectedGroupId(e.target.value ? Number(e.target.value) : '')} 
            disabled={!selectedRoom || groups.length === 0}
            style={{ padding: 8, minWidth: 200 }}
          >
            <option value="">-- 맵핑 그룹 선택 --</option>
            {groups.map(g => (
              <option key={g.group_id} value={g.group_id}>{g.group_name}</option>
            ))}
          </select>
          
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 15 }}>
            {/* 수정됨: checkedRoles가 아닌 groupRoleIds를 순회합니다. */}
            {selectedGroupId && groupRoleIds.map(roleId => {
              const roleInfo = allRoles.find(r => r.role_id === roleId);
              const roleName = roleInfo ? roleInfo.role_name : `Role ${roleId}`;
              return (
                <label key={roleId} style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input 
                    type="checkbox" 
                    checked={checkedRoles.includes(roleId)} 
                    onChange={() => handleRoleToggle(roleId)}
                    disabled={mode === 'EXTENT' && !checkedRoles.includes(roleId) && checkedRoles.length >= 1}
                    style={{ marginRight: 5 }}
                  /> 
                  {roleName}
                </label>
              );
            })}
            {selectedGroupId && groupRoleIds.length === 0 && (
              <span style={{ color: '#aaa' }}>그룹에 포함된 포인트 롤이 없습니다.</span>
            )}
          </div>
        </div>
      </div>

    </div>
  );
};