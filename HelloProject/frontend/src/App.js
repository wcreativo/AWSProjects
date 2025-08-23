import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [apiMessage, setApiMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await axios.get('/api/');
        setApiMessage(response.data.message);
        setLoading(false);
      } catch (err) {
        setError('Error connecting to API');
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>HelloProject</h1>
        <div className="content">
          <h2>Hello World! It Works! 🚀</h2>
          
          <div className="api-section">
            <h3>API Response:</h3>
            {loading && <p>Loading...</p>}
            {error && <p className="error">{error}</p>}
            {apiMessage && (
              <div className="api-message">
                <p>{apiMessage}</p>
                <span className="project-name">From HelloProject Backend</span>
              </div>
            )}
          </div>

          <div className="features">
            <h3>Features:</h3>
            <ul>
              <li>✅ React Frontend</li>
              <li>✅ Django Ninja Backend</li>
              <li>✅ Docker Containerization</li>
              <li>✅ AWS Deployment Ready</li>
              <li>✅ Nginx Reverse Proxy</li>
            </ul>
          </div>

          <div className="tech-stack">
            <h3>Tech Stack:</h3>
            <div className="tech-grid">
              <span className="tech-item">React</span>
              <span className="tech-item">Django Ninja</span>
              <span className="tech-item">Docker</span>
              <span className="tech-item">AWS</span>
              <span className="tech-item">Nginx</span>
            </div>
          </div>
        </div>
      </header>
    </div>
  );
}

export default App;
