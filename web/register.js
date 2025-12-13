// Register page client logic (calls POST /register already supported by serve.ps1)
(function(){
  const form = document.getElementById('register-form');
  const message = document.getElementById('message');

  function showMessage(text,isError=true){
    message.textContent = text;
    message.style.color = isError ? 'var(--danger)' : 'green';
  }

  form.addEventListener('submit', async function(ev){
    ev.preventDefault();
    const name = document.getElementById('reg-name').value.trim();
    const email = document.getElementById('reg-email').value.trim();
    const password = document.getElementById('reg-password').value;
    if(!name || !email || !password){ showMessage('All fields are required.'); return; }
    if(password.length < 6){ showMessage('Password must be at least 6 characters.'); return; }

    showMessage('Creating account...', false);
    try{
      const res = await fetch('/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password })
      });
      const data = await res.json();
      if(res.ok){
        showMessage('Account created! Redirecting to sign in...', false);
        setTimeout(()=>{ window.location.href = 'index.html'; }, 700);
      } else {
        showMessage(data.error || 'Unable to create account.');
      }
    } catch(e){
      console.error(e);
      showMessage('Network error - try again.');
    }
  });
})();

