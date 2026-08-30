// Click any node in the diagram -> show its data-info line in the note area.
// Purely static/client-side: no fetch, no PHP, no backend of any kind —
// this file is decoration only, matching the "non-PHP site" requirement
// for this bonus service.

document.addEventListener('DOMContentLoaded', () => {
  const note = document.getElementById('note');
  const nodes = document.querySelectorAll('.node');

  nodes.forEach((node) => {
    node.addEventListener('click', () => {
      note.textContent = node.dataset.info;
    });
  });

  // highlight the edges touching a node while hovering it
  const edgeMap = {
    nginx:        ['e-browser-nginx', 'e-nginx-wp'],
    static:       ['e-browser-static'],
    adminer:      ['e-browser-adminer', 'e-adminer-mariadb'],
    portainer:    ['e-browser-portainer'],
    ftp:          ['e-ftpclient-ftp', 'e-ftp-vol'],
    wordpress:    ['e-nginx-wp', 'e-wp-mariadb', 'e-wp-redis', 'e-wp-vol'],
    redis:        ['e-wp-redis'],
    mariadb:      ['e-wp-mariadb', 'e-adminer-mariadb', 'e-db-vol'],
  };

  nodes.forEach((node) => {
    const key = Object.keys(edgeMap).find((k) =>
      node.textContent.toLowerCase().includes(k)
    );
    if (!key) return;

    node.addEventListener('mouseenter', () => {
      edgeMap[key].forEach((id) => {
        const el = document.getElementById(id);
        if (el) el.style.opacity = '1';
      });
    });
    node.addEventListener('mouseleave', () => {
      edgeMap[key].forEach((id) => {
        const el = document.getElementById(id);
        if (el) el.style.opacity = '';
      });
    });
  });
});
