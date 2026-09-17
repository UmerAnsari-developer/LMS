const root = document.documentElement;
const sidebar = document.querySelector('#sidebar');
const page = document.querySelector('#page');
const pageCrumb = document.querySelector('#pageCrumb');
const toast = document.querySelector('#toast');
const toastText = document.querySelector('#toastText');
const modalBackdrop = document.querySelector('#modalBackdrop');
const modalTitle = document.querySelector('#modalTitle');
const modalDescription = document.querySelector('#modalDescription');
const dashboardMarkup = page.innerHTML;

const datasets = {
  students: { title:'Students', kicker:'USER DIRECTORY', description:'Manage student accounts, borrowing access, and membership status.', columns:['STUDENT','CONTACT','MEMBERSHIP','BORROWED','STATUS'], rows:[['Riya Shah','riya.shah@central.edu','STU-00841','8 books','Active'],['Marcus Lee','marcus.lee@central.edu','STU-00729','3 books','Active'],['Sofia Patel','sofia.patel@central.edu','STU-00618','5 books','Review'],['Noah Williams','noah.williams@central.edu','STU-00592','0 books','Inactive']] },
  librarians: { title:'Librarians', kicker:'STAFF DIRECTORY', description:'Manage librarians, roles, branches, and operational access.', columns:['LIBRARIAN','CONTACT','ROLE','BRANCH','STATUS'], rows:[['Anika Rao','anika.rao@central.edu','Head librarian','Central Library','Active'],['Daniel Kim','daniel.kim@central.edu','Circulation desk','Central Library','Active'],['Maya Johnson','maya.johnson@central.edu','Catalog manager','West Branch','Active'],['Owen Carter','owen.carter@central.edu','Assistant librarian','East Branch','On leave']] },
  books: { title:'Books', kicker:'CATALOG MANAGEMENT', description:'Search, register, update, and organize every title in the library catalog.', columns:['TITLE','AUTHOR','CATEGORY','ISBN','COPIES','STATUS'], rows:[['Atomic Habits','James Clear','Personal growth','978-0735211292','18 / 20','Available'],['Clean Code','Robert C. Martin','Technology','978-0132350884','7 / 12','Low stock'],['The Alchemist','Paulo Coelho','Fiction','978-0062315007','22 / 22','Available'],['The Design of Everyday Things','Don Norman','Design','978-0465050659','2 / 8','On loan']] },
  categories: { title:'Categories', kicker:'CATALOG STRUCTURE', description:'Organize books into searchable subject categories.', columns:['CATEGORY','BOOKS','ISSUED','POPULARITY','STATUS'], rows:[['Technology','1,840','324','High','Active'],['Fiction','3,120','488','High','Active'],['Design','860','121','Medium','Active'],['History','1,204','86','Medium','Active']] },
  authors: { title:'Authors', kicker:'CATALOG STRUCTURE', description:'Maintain author records and connect them to catalog titles.', columns:['AUTHOR','BOOKS','ACTIVE LOANS','TOP TITLE','STATUS'], rows:[['James Clear','12','38','Atomic Habits','Active'],['Robert C. Martin','9','21','Clean Code','Active'],['Don Norman','7','14','The Design of Everyday Things','Active'],['Paulo Coelho','24','46','The Alchemist','Active']] },
  publishers: { title:'Publishers', kicker:'CATALOG STRUCTURE', description:'Manage publisher profiles, contact details, and title relationships.', columns:['PUBLISHER','BOOKS','CONTACT','LAST ORDER','STATUS'], rows:[['Penguin Random House','428','orders@penguin.com','12 Sep 2026','Active'],['HarperCollins','312','library@harpercollins.com','08 Sep 2026','Active'],['O’Reilly Media','86','sales@oreilly.com','02 Sep 2026','Review'],['Bloomsbury','104','trade@bloomsbury.com','28 Aug 2026','Active']] },
  transactions: { title:'All transactions', kicker:'CIRCULATION OPERATIONS', description:'Review every issue, return, renewal, and fine event across the library.', columns:['TRANSACTION','MEMBER','BOOK','DATE','TYPE','STATUS'], rows:[['TX-28491','Riya Shah','Atomic Habits','17 Sep 2026','Issue','Open'],['TX-28490','Marcus Lee','Clean Code','17 Sep 2026','Return','Completed'],['TX-28489','Sofia Patel','The Alchemist','16 Sep 2026','Renewal','Approved'],['TX-28488','Noah Williams','Design Basics','16 Sep 2026','Issue','Open']] },
  issued: { title:'Issued books', kicker:'CIRCULATION OPERATIONS', description:'Track all books currently checked out by members.', columns:['BOOK','MEMBER','ISSUED','DUE DATE','RENEWALS','STATUS'], rows:[['Atomic Habits','Riya Shah','10 Sep 2026','24 Sep 2026','0','On time'],['Clean Code','Daniel Morris','04 Sep 2026','18 Sep 2026','1','On time'],['The Alchemist','Sofia Patel','01 Sep 2026','15 Sep 2026','1','Overdue'],['Design Basics','Marcus Lee','12 Sep 2026','26 Sep 2026','0','On time']] },
  returned: { title:'Returned books', kicker:'CIRCULATION OPERATIONS', description:'Review recent returns, condition checks, and processing history.', columns:['BOOK','MEMBER','RETURNED','CONDITION','PROCESSED BY','STATUS'], rows:[['Clean Code','Marcus Lee','17 Sep 2026','Good','Daniel Kim','Completed'],['The Hobbit','Ava Turner','17 Sep 2026','Good','Anika Rao','Completed'],['Sapiens','Liam Chen','16 Sep 2026','Minor wear','Maya Johnson','Review'],['Deep Work','Emma Davis','16 Sep 2026','Good','Daniel Kim','Completed']] },
  overdue: { title:'Overdue books', kicker:'CIRCULATION OPERATIONS', description:'Follow up on overdue books, outstanding fines, and member reminders.', columns:['BOOK','MEMBER','DUE DATE','DAYS LATE','FINE','ACTION'], rows:[['Atomic Habits','Riya Shah','14 Sep 2026','3 days','$4.50','Reminder sent'],['The Design of Everyday Things','Marcus Lee','15 Sep 2026','2 days','$3.00','Reminder sent'],['Clean Code','Sofia Patel','16 Sep 2026','1 day','$1.50','Pending'],['The Pragmatic Programmer','Owen Carter','12 Sep 2026','5 days','$7.50','Escalated']] },
  renewals: { title:'Renewals', kicker:'CIRCULATION OPERATIONS', description:'Approve, review, and audit member renewal requests.', columns:['REQUEST','MEMBER','BOOK','REQUESTED','PREVIOUS LOANS','STATUS'], rows:[['RN-1042','Sofia Patel','The Alchemist','17 Sep 2026','1','Approved'],['RN-1041','Marcus Lee','Clean Code','16 Sep 2026','1','Pending'],['RN-1040','Riya Shah','Atomic Habits','16 Sep 2026','0','Approved'],['RN-1039','Emma Davis','Sapiens','15 Sep 2026','2','Declined']] }
};

function showToast(message, title = 'Action completed') {
  toast.querySelector('strong').textContent = title;
  toastText.textContent = message;
  toast.classList.add('show');
  clearTimeout(window.toastTimer);
  window.toastTimer = setTimeout(() => toast.classList.remove('show'), 3000);
}
function openModal(title, description) { modalTitle.textContent = title; modalDescription.textContent = description || 'Choose an administrative task to continue.'; modalBackdrop.classList.add('open'); }
function closeModal() { modalBackdrop.classList.remove('open'); }
function escapeHtml(value) { return String(value).replace(/[&<>'"]/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[char])); }
function setActivePage(name) {
  pageCrumb.textContent = name.toUpperCase();
  document.querySelectorAll('.nav-item').forEach(nav => nav.classList.remove('active'));
  const match = document.querySelector(`.nav-item[data-page="${name}"]`);
  if (match) match.classList.add('active');
}
function statusClass(value) {
  const text = String(value).toLowerCase();
  if (text.includes('overdue') || text.includes('declined') || text.includes('inactive') || text.includes('review') || text.includes('low')) return 'danger';
  if (text.includes('pending') || text.includes('reminder') || text.includes('on leave') || text.includes('escalated')) return 'warning';
  return 'success';
}
function tableMarkup(data) {
  return `<div class="operation-table-wrap"><table class="operation-table"><thead><tr>${data.columns.map(column => `<th>${escapeHtml(column)}</th>`).join('')}<th></th></tr></thead><tbody>${data.rows.map(row => `<tr>${row.map((cell, index) => `<td>${index === 0 ? `<strong>${escapeHtml(cell)}</strong>` : index === row.length - 1 ? `<span class="status ${statusClass(cell)}">${escapeHtml(cell)}</span>` : escapeHtml(cell)}</td>`).join('')}<td><button class="row-menu operation-menu">•••</button></td></tr>`).join('')}</tbody></table></div>`;
}
function operationHeader(title, description, primary = 'Add new') {
  return `<div class="operation-heading"><div><p class="eyebrow">ADMIN / OPERATIONS</p><h1>${escapeHtml(title)}</h1><p class="subheading">${escapeHtml(description)}</p></div><div class="heading-actions"><button class="btn btn-ghost operation-export">↓ Export</button><button class="btn btn-primary operation-primary">＋ ${escapeHtml(primary)}</button></div></div>`;
}
function renderTableOperation(name) {
  const data = datasets[name];
  const primary = name === 'overdue' ? 'Send reminders' : name === 'transactions' ? 'New transaction' : name === 'renewals' ? 'Review requests' : `Add ${name === 'books' ? 'book' : name.slice(0, -1)}`;
  page.innerHTML = `${operationHeader(data.title, data.description, primary)}<div class="operation-stats"><div><span>RECORDS</span><strong>${data.rows.length * 321}</strong><small>↗ 8.4% this month</small></div><div><span>ACTIVE</span><strong>${data.rows.length * 204}</strong><small>Across all branches</small></div><div><span>NEEDS ATTENTION</span><strong class="danger-text">${name === 'overdue' ? '12' : name === 'renewals' ? '8' : '4'}</strong><small>Review recommended</small></div></div><article class="panel operation-panel"><div class="panel-header"><div><span class="panel-kicker">${escapeHtml(data.kicker)}</span><h2>${escapeHtml(data.title)} directory</h2></div><div class="operation-tools"><label class="inline-search">⌕ <input class="operation-search" placeholder="Search records..." /></label><button class="filter-btn operation-filter">☷ Filter</button></div></div>${tableMarkup(data)}</article><div class="operation-foot"><span>Showing ${data.rows.length} of ${data.rows.length * 321} records</span><button class="text-btn operation-next">Load more →</button></div>`;
  bindOperationEvents(name);
}
function renderReports() {
  page.innerHTML = `${operationHeader('Reports', 'Turn library activity into actionable reports for your team.', 'Build report')}<div class="report-grid"><button class="report-card" data-report="Book inventory report"><span class="report-icon cyan-icon">▤</span><strong>Book inventory report</strong><small>Catalog size, availability, and stock health</small><b>→</b></button><button class="report-card" data-report="User activity report"><span class="report-icon purple-icon">♙</span><strong>User activity report</strong><small>Membership growth and borrowing patterns</small><b>→</b></button><button class="report-card" data-report="Circulation report"><span class="report-icon amber-icon">⇄</span><strong>Circulation report</strong><small>Issues, returns, and renewal trends</small><b>→</b></button><button class="report-card" data-report="Overdue report"><span class="report-icon red-icon">!</span><strong>Overdue report</strong><small>Late returns, fines, and reminder status</small><b>→</b></button><button class="report-card" data-report="Fine report"><span class="report-icon green-icon">$</span><strong>Fine report</strong><small>Collected, outstanding, and waived fines</small><b>→</b></button></div><article class="panel report-preview"><div class="panel-header"><div><span class="panel-kicker">REPORT PREVIEW</span><h2>Monthly circulation summary</h2></div><span class="status success">Ready to export</span></div><div class="report-bars"><div><span>Issued</span><i><b style="width:82%"></b></i><strong>1,849</strong></div><div><span>Returned</span><i><b style="width:64%"></b></i><strong>1,208</strong></div><div><span>Renewed</span><i><b style="width:38%"></b></i><strong>421</strong></div><div><span>Overdue</span><i><b class="bar-danger" style="width:12%"></b></i><strong>12</strong></div></div></article>`;
  bindOperationEvents('reports');
  document.querySelectorAll('.report-card').forEach(card => card.addEventListener('click', () => openModal(card.dataset.report, 'Choose a date range and export format to generate this report.')));
}
function renderSettings() {
  page.innerHTML = `${operationHeader('Settings', 'Configure the library identity, borrowing rules, fines, and system preferences.', 'Save changes')}<div class="settings-grid"><article class="panel settings-card"><span class="panel-kicker">LIBRARY INFORMATION</span><h2>Central Library</h2><label>Library name<input value="Central Library" /></label><label>Contact email<input value="admin@centrallibrary.edu" /></label><label>Opening hours<input value="Mon–Sat · 08:00–20:00" /></label></article><article class="panel settings-card"><span class="panel-kicker">BORROWING RULES</span><h2>Member access</h2><label>Maximum books<input value="5 books" /></label><label>Loan duration<input value="14 days" /></label><label>Renewal limit<input value="2 renewals" /></label></article><article class="panel settings-card"><span class="panel-kicker">FINE RULES</span><h2>Overdue policy</h2><label>Daily fine<input value="$1.50" /></label><label>Maximum fine<input value="$25.00" /></label><label>Grace period<input value="1 day" /></label></article><article class="panel settings-card"><span class="panel-kicker">SYSTEM PREFERENCES</span><h2>Admin console</h2><label class="toggle-row">Email reminders <input type="checkbox" checked /><i></i></label><label class="toggle-row">Auto backups <input type="checkbox" checked /><i></i></label><label class="toggle-row">Dark theme <input type="checkbox" checked /><i></i></label></article></div>`;
  document.querySelector('.operation-primary').addEventListener('click', () => showToast('Settings saved successfully.', 'Configuration updated'));
  document.querySelectorAll('.settings-card input').forEach(input => input.addEventListener('change', () => showToast('Unsaved preference changed.', 'Draft setting')));
}
function renderProfile() {
  page.innerHTML = `${operationHeader('Profile', 'Manage your administrator identity and account security.', 'Edit profile')}<div class="profile-layout"><article class="panel profile-card"><div class="large-avatar">AM</div><h2>Alex Morgan</h2><p>Super administrator</p><span class="status success">Account active</span><div class="profile-meta"><div><span>Email</span><strong>alex.morgan@centrallibrary.edu</strong></div><div><span>Last login</span><strong>17 Sep 2026 · 08:42</strong></div><div><span>Member since</span><strong>12 Mar 2024</strong></div></div></article><article class="panel profile-form"><span class="panel-kicker">ACCOUNT DETAILS</span><h2>Personal information</h2><label>Full name<input value="Alex Morgan" /></label><label>Email address<input value="alex.morgan@centrallibrary.edu" /></label><label>Role<input value="Super administrator" disabled /></label><div class="form-actions"><button class="btn btn-ghost profile-password">Change password</button><button class="btn btn-primary profile-save">Save profile</button></div></article></div>`;
  document.querySelector('.profile-save').addEventListener('click', () => showToast('Your profile has been updated.', 'Profile saved'));
  document.querySelector('.profile-password').addEventListener('click', () => openModal('Change password', 'A secure password reset workflow would open here.'));
}
function renderDashboard() { page.innerHTML = dashboardMarkup; bindDashboardEvents(); setActivePage('dashboard'); }
function renderPage(name) { setActivePage(name); if (name === 'dashboard') renderDashboard(); else if (name === 'reports') renderReports(); else if (name === 'settings') renderSettings(); else if (name === 'profile') renderProfile(); else renderTableOperation(name); }
function bindOperationEvents(name) {
  document.querySelector('.operation-primary')?.addEventListener('click', () => openModal(name === 'overdue' ? 'Send overdue reminders' : `Add ${name.slice(0, -1)}`, 'This prototype is ready for the next form step. Connect it to the existing LMS database workflow.'));
  document.querySelector('.operation-export')?.addEventListener('click', () => showToast(`${datasets[name]?.title || 'Report'} export is being prepared.`, 'Export started'));
  document.querySelector('.operation-filter')?.addEventListener('click', () => showToast('Advanced filters are ready to configure.', 'Filter panel'));
  document.querySelector('.operation-next')?.addEventListener('click', () => showToast('All prototype records are already visible.', 'End of list'));
  document.querySelector('.operation-search')?.addEventListener('input', event => { const query = event.target.value.toLowerCase(); document.querySelectorAll('.operation-table tbody tr').forEach(row => row.hidden = query && !row.textContent.toLowerCase().includes(query)); });
  document.querySelectorAll('.operation-menu').forEach(button => button.addEventListener('click', () => openModal('Record actions', 'View details, edit this record, or archive it from the library system.')));
}
function bindDashboardEvents() {
  document.querySelector('#exportBtn')?.addEventListener('click', () => showToast('Your circulation report is being prepared.', 'Export started'));
  document.querySelector('#quickActionBtn')?.addEventListener('click', () => openModal('Start an operation', 'Choose a quick operation from the shortcuts below or use the navigation tree.'));
  document.querySelector('#notificationBtn')?.addEventListener('click', () => showToast('3 notifications: 2 overdue alerts, 1 backup complete.', 'Notifications'));
  document.querySelector('#rangeSelect')?.addEventListener('change', event => showToast(`Chart updated to ${event.target.value.toLowerCase()}.`, 'Activity range updated'));
  document.querySelector('.filter-btn')?.addEventListener('click', () => showToast('Filters are ready to configure in the full application.', 'Filter panel'));
  document.querySelectorAll('.action-row').forEach(button => button.addEventListener('click', () => openModal(button.dataset.action, `This prototype is ready for the ${button.dataset.action.toLowerCase()} workflow.`)));
  document.querySelectorAll('.row-menu').forEach(button => button.addEventListener('click', () => openModal('Overdue record actions', 'Send a reminder, record a return, or waive the fine for this member.')));
  document.querySelector('#globalSearch')?.addEventListener('input', event => { const query = event.target.value.trim().toLowerCase(); document.querySelectorAll('tbody tr').forEach(row => row.hidden = query && !row.textContent.toLowerCase().includes(query)); });
}

document.querySelectorAll('.has-children').forEach(item => item.addEventListener('click', () => { const children = item.nextElementSibling; const isOpen = children.classList.toggle('open'); item.querySelector('i').textContent = isOpen ? '⌃' : '⌄'; }));
document.querySelectorAll('[data-page]').forEach(item => item.addEventListener('click', event => { if (item.classList.contains('has-children')) return; renderPage(item.dataset.page); if (window.innerWidth < 760) sidebar.classList.remove('open'); event.stopPropagation(); }));
document.querySelector('#menuToggle').addEventListener('click', () => sidebar.classList.add('open'));
document.querySelector('#sidebarClose').addEventListener('click', () => sidebar.classList.remove('open'));
document.querySelector('#themeToggle').addEventListener('click', () => { const next = root.dataset.theme === 'dark' ? 'light' : 'dark'; root.dataset.theme = next; document.querySelector('#themeToggle').textContent = next === 'dark' ? '☼' : '☾'; showToast(`${next === 'dark' ? 'Dark' : 'Light'} theme enabled.`, 'Appearance updated'); });
document.querySelector('#modalClose').addEventListener('click', closeModal);
document.querySelector('#modalCancel').addEventListener('click', closeModal);
document.querySelector('#modalConfirm').addEventListener('click', () => { closeModal(); showToast('Prototype workflow started successfully.', 'Operation started'); });
modalBackdrop.addEventListener('click', event => { if (event.target === modalBackdrop) closeModal(); });
document.addEventListener('keydown', event => { if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); document.querySelector('#globalSearch').focus(); } if (event.key === 'Escape') closeModal(); });
bindDashboardEvents();
