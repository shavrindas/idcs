import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { ChartMappingPage } from './pages/ChartMappingPage';
import { ChartViewerPage }  from './pages/ChartViewerPage';
import { PRIndexingPage }    from './pages/PRIndexingPage';
import { FacilityManagerPage } from './pages/FacilityManagerPage';
import './App.css';

function App() {
  return (
    <Router>
      <div style={{ 
        display: 'flex', 
        flexDirection: 'column', 
        height: '100vh', 
        padding: 10, 
        backgroundColor: '#121212', 
        color: '#ffffff',
        boxSizing: 'border-box' 
      }}>
        <header style={{ border: '2px solid #e91e63', padding: 20, textAlign: 'center', marginBottom: 10 }}>
          <h2 style={{ margin: 0, color: '#e91e63' }}>IDCool Systems Console</h2>
        </header>
        
        <nav style={{ border: '2px solid #ff9800', padding: 15, marginBottom: 10, display: 'flex', gap: 20, alignItems: 'center' }}>
          <strong style={{ color: '#ff9800' }}>NAV</strong>
          <Link to="/" style={{ color: '#ffffff', textDecoration: 'none' }}>[맵핑 관리자]</Link>
          <Link to="/viewer" style={{ color: '#ffffff', textDecoration: 'none' }}>[웹 차트 뷰어]</Link>
          <Link to="/indexing" style={{ color: '#ffffff', textDecoration: 'none' }}>[명칭 인덱싱]</Link>
          <Link to="/facility-manager" style={{ color: '#ffffff', textDecoration: 'none' }}>[시설/호실 관리]</Link>
        </nav>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
          <Routes>
            <Route path="/" element={<ChartMappingPage />} />
            <Route path="/viewer" element={<ChartViewerPage />} />
            <Route path="/indexing" element={<PRIndexingPage />} />
            <Route path="/facility-manager" element={<FacilityManagerPage />} />
          </Routes>
        </div>

        <footer style={{ border: '2px solid #673ab7', padding: 20, textAlign: 'center', marginTop: 10 }}>
          <span style={{ color: '#673ab7', fontWeight: 'bold' }}>IDCool Systems Cloud</span>
        </footer>
      </div>
    </Router>
  );
}

export default App;