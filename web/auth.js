// Simple client-side auth helpers (demo only)
(function(){
  window.auth = {
    getUser: function(){
      try{ return JSON.parse(window.localStorage.getItem('user')); } catch(e){ return null; }
    },
    logout: function(){ window.localStorage.removeItem('user'); window.location.href = 'index.html'; },
    requireAuth: function(redirectTo='index.html'){
      if(!window.auth.getUser()){
        window.location.href = redirectTo;
        return false;
      }
      return true;
    }
  };
})();

