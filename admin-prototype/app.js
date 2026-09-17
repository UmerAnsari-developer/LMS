const root = document.documentElement;
const sidebar = document.querySelector('#sidebar');
const pageCrumb = document.querySelector('#pageCrumb');
const toast = document.querySelector('#toast');
const toastText = document.querySelector('#toastText');
const modalBackdrop = document.querySelector('#modalBackdrop');
const modalTitle = document.querySelector('#modalTitle');
const modalDescription = document.querySelector('#modalDescription');

function showToast(message, title = 'Action completed') {
  toast.querySelector('strong').textContent = title;
  toastText.textContent = message;
  toast.classList.add('show');
  clearTimeout(window.toastTimer);
  window.toastTimer = setTimeout(() => toast.classList.remove('show'), 3000);
}

function openModal(title, description) {
  modalTitle.textContent = title;
  modalDescription.textContent = description || 'Choose an administrative task to continue.';
  modalBackdrop.classList.add('open');
}
function closeModal() { modalBackdrop.classList.remove('open'); }

// Expand/collapse sidebar groups while preserving the active page.
document.querySelectorAll('.has-children').forEach((item) => {
  item.addEventListener('click', () => {
    const children = item.nextElementSibling;
    const isOpen = children.classList.toggle('open');
    item.querySelector('i').textContent = isOpen ? '⌃' : '⌄';
  });
});

document.querySelectorAll('[data-page]').forEach((item) => {
  item.addEventListener('click', (event) => {
    const page = item.dataset.page;
    if (item.classList.contains('has-children')) return;
    document.querySelectorAll('.nav-item').forEach((nav) => nav.classList.remove('active'));
    const parent = item.closest('.nav-children')?.previousElementSibling;
    if (parent) parent.classList.add('active');
    if (item.classList.contains('nav-item')) item.classList.add('active');
    pageCrumb.textContent = page.toUpperCase();
    if (page !== 'dashboard') {
      showToast(`${page.charAt(0).toUpperCase() + page.slice(1)} module selected.`, 'Navigation ready');
    }
    if (window.innerWidth < 760) sidebar.classList.remove('open');
    event.stopPropagation();
  });
});

document.querySelector('#menuToggle').addEventListener('click', () => sidebar.classList.add('open'));
document.querySelector('#sidebarClose').addEventListener('click', () => sidebar.classList.remove('open'));
document.querySelector('#themeToggle').addEventListener('click', () => {
  const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
  root.dataset.theme = next;
  document.querySelector('#themeToggle').textContent = next === 'dark' ? '☼' : '☾';
  showToast(`${next === 'dark' ? 'Dark' : 'Light'} theme enabled.`, 'Appearance updated');
});

document.querySelector('#quickActionBtn').addEventListener('click', () => openModal('Start an operation', 'Choose a quick operation from the shortcuts below or use the navigation tree.'));
document.querySelectorAll('.action-row').forEach((button) => {
  button.addEventListener('click', () => openModal(button.dataset.action, `This prototype is ready for the ${button.dataset.action.toLowerCase()} workflow.`));
});
document.querySelector('#exportBtn').addEventListener('click', () => showToast('Your circulation report is being prepared.', 'Export started'));
document.querySelector('#notificationBtn').addEventListener('click', () => showToast('3 notifications: 2 overdue alerts, 1 backup complete.', 'Notifications'));
document.querySelector('#modalClose').addEventListener('click', closeModal);
document.querySelector('#modalCancel').addEventListener('click', closeModal);
document.querySelector('#modalConfirm').addEventListener('click', () => { closeModal(); showToast('Prototype workflow started successfully.', 'Operation started'); });
modalBackdrop.addEventListener('click', (event) => { if (event.target === modalBackdrop) closeModal(); });
document.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); document.querySelector('#globalSearch').focus(); }
  if (event.key === 'Escape') closeModal();
});

document.querySelector('#globalSearch').addEventListener('input', (event) => {
  const query = event.target.value.trim().toLowerCase();
  document.querySelectorAll('tbody tr').forEach((row) => {
    row.hidden = query && !row.textContent.toLowerCase().includes(query);
  });
  if (query) showToast(`Filtering records for “${query}”.`, 'Search active');
});
document.querySelector('#rangeSelect').addEventListener('change', (event) => showToast(`Chart updated to ${event.target.value.toLowerCase()}.`, 'Activity range updated'));
document.querySelectorAll('.row-menu').forEach((button) => button.addEventListener('click', () => openModal('Overdue record actions', 'Send a reminder, record a return, or waive the fine for this member.')));
document.querySelector('.filter-btn').addEventListener('click', () => showToast('Filters are ready to configure in the full application.', 'Filter panel'));
