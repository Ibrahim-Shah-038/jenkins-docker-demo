const handleLogin = async (e) => {
    e.preventDefault();
    const res = await fetch('http://127.0.0.1:8000/api/login/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (res.ok) {
      localStorage.setItem('token', data.token);
      window.location.href = '/';  // redirect to homepage
    } else {
      alert(data.error);
    }
  };
  