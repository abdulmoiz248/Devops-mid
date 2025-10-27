// Dashboard functionality for Image Processing System

// Tab switching
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const tabName = btn.dataset.tab;
    switchTab(tabName);
  });
});

function switchTab(tabName) {
  // Update active tab button
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.classList.remove('active');
    if (btn.dataset.tab === tabName) {
      btn.classList.add('active');
    }
  });
  
  // Update active tab content
  document.querySelectorAll('.tab-content').forEach(content => {
    content.classList.remove('active');
  });
  document.getElementById(`${tabName}-tab`).classList.add('active');
  
  // Load data for the tab
  if (tabName === 'products') {
    loadProducts();
  } else if (tabName === 'images') {
    loadImages();
  }
}

// ===== UPLOAD TAB =====
const csvInput = document.getElementById('csvFile');
const fileNameSpan = document.getElementById('fileName');
const uploadBtn = document.getElementById('uploadBtn');
const uploadResult = document.getElementById('uploadResult');
const taskList = document.getElementById('taskList');

csvInput.addEventListener('change', (e) => {
  const file = e.target.files[0];
  fileNameSpan.textContent = file ? file.name : 'Choose CSV file...';
});

uploadBtn.addEventListener('click', async () => {
  const file = csvInput.files[0];
  if (!file) {
    showMessage(uploadResult, 'Please select a CSV file.', 'error');
    return;
  }

  const form = new FormData();
  form.append('file', file);

  uploadBtn.disabled = true;
  uploadBtn.innerHTML = '<span class="btn-text">⏳ Uploading...</span>';
  showMessage(uploadResult, 'Uploading and processing...', 'info');

  try {
    const resp = await fetch('/upload', { method: 'POST', body: form });
    const data = await resp.json();
    
    if (!resp.ok) {
      showMessage(uploadResult, '❌ Error: ' + (data.error || resp.statusText), 'error');
      return;
    }
    
    showMessage(uploadResult, `✅ Successfully submitted ${data.task_ids.length} task(s) for processing!`, 'success');
    displayTaskIds(data.task_ids);
    
    csvInput.value = '';
    fileNameSpan.textContent = 'Choose CSV file...';
    
  } catch (err) {
    showMessage(uploadResult, '❌ Network error: ' + err.message, 'error');
  } finally {
    uploadBtn.disabled = false;
    uploadBtn.innerHTML = '<span class="btn-text">Upload & Process</span>';
  }
});

function displayTaskIds(taskIds) {
  taskList.innerHTML = '<h3>Task IDs:</h3>';
  const ul = document.createElement('ul');
  ul.className = 'task-id-list';
  
  taskIds.forEach(id => {
    const li = document.createElement('li');
    li.innerHTML = `
      <code>${id}</code>
      <button class="btn-small" onclick="checkTaskById('${id}')">Check</button>
    `;
    ul.appendChild(li);
  });
  
  taskList.appendChild(ul);
}

// ===== TASKS TAB =====
const checkBtn = document.getElementById('checkBtn');
const taskIdInput = document.getElementById('taskIdInput');
const statusResult = document.getElementById('statusResult');

checkBtn.addEventListener('click', () => checkTaskStatus());
taskIdInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') checkTaskStatus();
});

async function checkTaskStatus() {
  const id = taskIdInput.value.trim();
  if (!id) {
    showMessage(statusResult, 'Please enter a task ID', 'error');
    return;
  }
  
  checkBtn.disabled = true;
  checkBtn.innerHTML = '<span class="btn-text">⏳ Checking...</span>';
  showMessage(statusResult, 'Fetching status...', 'info');
  
  try {
    const resp = await fetch('/status/' + encodeURIComponent(id));
    const data = await resp.json();
    
    if (!resp.ok) {
      showMessage(statusResult, '❌ Error: ' + (data.error || resp.statusText), 'error');
      return;
    }
    
    displayStatus(data);
    
  } catch (err) {
    showMessage(statusResult, '❌ Network error: ' + err.message, 'error');
  } finally {
    checkBtn.disabled = false;
    checkBtn.innerHTML = '<span class="btn-text">Check Status</span>';
  }
}

window.checkTaskById = function(taskId) {
  switchTab('tasks');
  setTimeout(() => {
    taskIdInput.value = taskId;
    taskIdInput.scrollIntoView({ behavior: 'smooth', block: 'center' });
    setTimeout(() => checkTaskStatus(), 300);
  }, 100);
};

function displayStatus(data) {
  const statusEmoji = {
    'SUCCESS': '✅',
    'FAILURE': '❌',
    'PENDING': '⏳',
    'PROGRESS': '🔄',
    'UNKNOWN': '❓'
  };
  
  const emoji = statusEmoji[data.status] || '❓';
  const statusClass = data.status.toLowerCase();
  
  statusResult.innerHTML = `
    <div class="status-card ${statusClass}">
      <h3>${emoji} Status: ${data.status}</h3>
      <p><strong>Task ID:</strong> <code>${data.task_id}</code></p>
      ${data.result ? `<div class="result-data"><strong>Result:</strong><pre>${JSON.stringify(data.result, null, 2)}</pre></div>` : ''}
    </div>
  `;
}

// ===== PRODUCTS TAB =====
async function loadProducts() {
  const tbody = document.getElementById('productsTableBody');
  const resultDiv = document.getElementById('productsResult');
  
  tbody.innerHTML = '<tr><td colspan="5" class="loading">Loading products...</td></tr>';
  resultDiv.innerHTML = '';
  
  try {
    const resp = await fetch('/api/products');
    const data = await resp.json();
    
    if (!resp.ok) {
      showMessage(resultDiv, '❌ Error loading products: ' + (data.error || resp.statusText), 'error');
      tbody.innerHTML = '<tr><td colspan="5" class="empty">Failed to load products</td></tr>';
      return;
    }
    
    if (data.products.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="empty">No products found. Add your first product!</td></tr>';
      return;
    }
    
    tbody.innerHTML = data.products.map(product => `
      <tr>
        <td>${product.id}</td>
        <td><strong>${product.serial_number}</strong></td>
        <td>${product.product_name}</td>
        <td><span class="badge">${product.image_count} images</span></td>
        <td class="actions">
          <button class="btn-icon" onclick="viewProduct(${product.id})" title="View">👁️</button>
          <button class="btn-icon" onclick="editProduct(${product.id})" title="Edit">✏️</button>
          <button class="btn-icon delete" onclick="deleteProduct(${product.id})" title="Delete">🗑️</button>
        </td>
      </tr>
    `).join('');
    
  } catch (err) {
    showMessage(resultDiv, '❌ Network error: ' + err.message, 'error');
    tbody.innerHTML = '<tr><td colspan="5" class="empty">Network error</td></tr>';
  }
}

document.getElementById('addProductBtn').addEventListener('click', () => {
  document.getElementById('modalTitle').textContent = 'Add Product';
  document.getElementById('productId').value = '';
  document.getElementById('serialNumber').value = '';
  document.getElementById('productName').value = '';
  document.getElementById('productModal').classList.add('show');
});

document.getElementById('productForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const productId = document.getElementById('productId').value;
  const serialNumber = document.getElementById('serialNumber').value;
  const productName = document.getElementById('productName').value;
  
  const method = productId ? 'PUT' : 'POST';
  const url = productId ? `/api/products/${productId}` : '/api/products';
  
  try {
    const resp = await fetch(url, {
      method: method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ serial_number: serialNumber, product_name: productName })
    });
    
    const data = await resp.json();
    
    if (!resp.ok) {
      alert('Error: ' + (data.error || resp.statusText));
      return;
    }
    
    closeModal();
    loadProducts();
    showMessage(document.getElementById('productsResult'), 
      `✅ ${data.message}`, 'success');
    
  } catch (err) {
    alert('Network error: ' + err.message);
  }
});

async function editProduct(id) {
  try {
    const resp = await fetch(`/api/products/${id}`);
    const data = await resp.json();
    
    if (!resp.ok) {
      alert('Error loading product: ' + (data.error || resp.statusText));
      return;
    }
    
    document.getElementById('modalTitle').textContent = 'Edit Product';
    document.getElementById('productId').value = data.id;
    document.getElementById('serialNumber').value = data.serial_number;
    document.getElementById('productName').value = data.product_name;
    document.getElementById('productModal').classList.add('show');
    
  } catch (err) {
    alert('Network error: ' + err.message);
  }
}

async function viewProduct(id) {
  try {
    const resp = await fetch(`/api/products/${id}`);
    const data = await resp.json();
    
    if (!resp.ok) {
      alert('Error loading product: ' + (data.error || resp.statusText));
      return;
    }
    
    const imagesList = data.images.length > 0 
      ? data.images.map(img => `
          <div class="image-item">
            <strong>Image #${img.id}</strong><br>
            Input: <a href="${img.input_image_url}" target="_blank">View</a><br>
            ${img.output_image_url ? `Output: <a href="${img.output_image_url}" target="_blank">View</a>` : 'Output: Not processed yet'}
          </div>
        `).join('')
      : '<p>No images for this product.</p>';
    
    alert(`Product Details:\n\nID: ${data.id}\nSerial: ${data.serial_number}\nName: ${data.product_name}\nImages: ${data.images.length}`);
    
  } catch (err) {
    alert('Network error: ' + err.message);
  }
}

async function deleteProduct(id) {
  if (!confirm('Are you sure you want to delete this product? This will also delete all associated images.')) {
    return;
  }
  
  try {
    const resp = await fetch(`/api/products/${id}`, { method: 'DELETE' });
    const data = await resp.json();
    
    if (!resp.ok) {
      alert('Error: ' + (data.error || resp.statusText));
      return;
    }
    
    loadProducts();
    showMessage(document.getElementById('productsResult'), 
      `✅ ${data.message}`, 'success');
    
  } catch (err) {
    alert('Network error: ' + err.message);
  }
}

// ===== IMAGES TAB =====
async function loadImages() {
  const tbody = document.getElementById('imagesTableBody');
  const resultDiv = document.getElementById('imagesResult');
  
  tbody.innerHTML = '<tr><td colspan="6" class="loading">Loading images...</td></tr>';
  resultDiv.innerHTML = '';
  
  try {
    const resp = await fetch('/api/products/images');
    const data = await resp.json();
    
    if (!resp.ok) {
      showMessage(resultDiv, '❌ Error loading images: ' + (data.error || resp.statusText), 'error');
      tbody.innerHTML = '<tr><td colspan="6" class="empty">Failed to load images</td></tr>';
      return;
    }
    
    if (data.images.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" class="empty">No images found. Upload a CSV to process images!</td></tr>';
      return;
    }
    
    tbody.innerHTML = data.images.map(img => `
      <tr>
        <td>${img.id}</td>
        <td>${img.product_name}</td>
        <td><strong>${img.serial_number}</strong></td>
        <td><button class="btn-link" onclick="viewImage('${img.input_image_url}')">View Input</button></td>
        <td>${img.output_image_url ? `<button class="btn-link" onclick="viewImage('${img.output_image_url}')">View Output</button>` : '<span class="text-muted">Not processed</span>'}</td>
        <td class="actions">
          <button class="btn-icon" onclick="copyUrl('${img.input_image_url}')" title="Copy Input URL">📋</button>
        </td>
      </tr>
    `).join('');
    
  } catch (err) {
    showMessage(resultDiv, '❌ Network error: ' + err.message, 'error');
    tbody.innerHTML = '<tr><td colspan="6" class="empty">Network error</td></tr>';
  }
}

function viewImage(url) {
  document.getElementById('modalImage').src = url;
  document.getElementById('imageModal').classList.add('show');
}

function copyUrl(url) {
  navigator.clipboard.writeText(url).then(() => {
    alert('URL copied to clipboard!');
  }).catch(err => {
    alert('Failed to copy URL');
  });
}

// ===== MODAL FUNCTIONS =====
function closeModal() {
  document.getElementById('productModal').classList.remove('show');
}

function closeImageModal() {
  document.getElementById('imageModal').classList.remove('show');
}

// Close modals on outside click
window.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal')) {
    e.target.classList.remove('show');
  }
});

// ===== UTILITY FUNCTIONS =====
function showMessage(element, message, type) {
  element.innerHTML = `<div class="message ${type}">${message}</div>`;
  setTimeout(() => {
    element.innerHTML = '';
  }, 5000);
}

// Auto-refresh products and images every 30 seconds if on those tabs
setInterval(() => {
  const activeTab = document.querySelector('.tab-content.active');
  if (activeTab.id === 'products-tab') {
    loadProducts();
  } else if (activeTab.id === 'images-tab') {
    loadImages();
  }
}, 30000);
