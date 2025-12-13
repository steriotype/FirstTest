// Login page client logic — now uses the /login endpoint and auth helpers.
import './auth.js';
(function(){
  const form = document.getElementById('login-form');
  const message = document.getElementById('message');
  const googleBtn = document.getElementById('google-signin');
  const forgotLink = document.getElementById('forgot-link');
  const forgotModal = document.getElementById('forgot-modal');
  const forgotForm = document.getElementById('forgot-form');
  const forgotEmail = document.getElementById('forgot-email');
  const forgotCancel = document.getElementById('forgot-cancel');

  function showMessage(text, isError=true){
    message.textContent = text;
    message.style.color = isError ? 'var(--danger)' : 'green';
  }

  form.addEventListener('submit', async function(ev){
    ev.preventDefault();
    message.textContent = '';
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;

    if(!username){
      showMessage('Please enter a username or email.');
      return;
    }
    if(!password){
      showMessage('Please enter a password.');
      return;
    }
    if(password.length < 6){
      showMessage('Password must be at least 6 characters.');
      return;
    }

    showMessage('Signing in...', false);
    try{
      const res = await fetch('/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const data = await res.json();
      if(res.ok && data.ok){
        showMessage('Signed in successfully!', false);
        // Save session locally (demo)
        window.localStorage.setItem('user', JSON.stringify(data.user));
        setTimeout(()=>{ window.location.href = 'dashboard.html'; }, 400);
      } else {
        showMessage(data.error || 'Invalid username or password.');
      }
    } catch(err){
      console.error(err);
      showMessage('Network error — try again.');
    }
  });

  // Google sign-in simulation / demo
  googleBtn.addEventListener('click', function(){
    showMessage('Opening Google sign-in...', false);
    // NOTE: For a real integration, implement OAuth on the server with PKCE and exchange callbacks.
    // This demo simulates a successful Google login after a short delay.
    setTimeout(()=>{
      const demoUser = { name: 'Google User', email: 'googleuser@example.com' };
      window.localStorage.setItem('user', JSON.stringify(demoUser));
      showMessage('Signed in with Google!', false);
      setTimeout(()=>{ window.location.href = 'dashboard.html'; }, 400);
    },900);
  });

  // Forgot password modal handlers
  forgotLink.addEventListener('click', ()=>{
    forgotModal.setAttribute('aria-hidden','false');
    forgotEmail.focus();
  });
  forgotCancel.addEventListener('click', ()=>{
    forgotModal.setAttribute('aria-hidden','true');
  });

  forgotForm.addEventListener('submit', async function(ev){
    ev.preventDefault();
    const email = forgotEmail.value.trim();
    if(!email){
      alert('Enter an email address');
      return;
    }
    // Check if email exists by fetching users.json (demo only)
    try{
      const resp = await fetch('/users.json');
      const users = await resp.json();
      const found = users && users.find(u => u.email && u.email.toLowerCase() === email.toLowerCase());
      forgotModal.setAttribute('aria-hidden','true');
      if(found){
        showMessage('If that email exists we sent reset instructions (demo).', false);
      } else {
        showMessage('If that email exists we sent reset instructions (demo).', false);
      }
    } catch(e){
      console.error(e);
      forgotModal.setAttribute('aria-hidden','true');
      showMessage('Unable to reach server for password reset (demo).');
    }
  });

})();
