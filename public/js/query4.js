document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('query4Form');
    const resultsContainer = document.getElementById('resultsContainer');

    form.addEventListener('submit', async function(e) {
        e.preventDefault();

        // Show loading state
        resultsContainer.innerHTML = `
            <div class="card">
                <div class="card-body text-center">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="mt-2">Loading results...</p>
                </div>
            </div>
        `;

        const formData = new FormData(form);
        const data = Object.fromEntries(formData);

        try {
            const response = await fetch('/api/query4', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (!result.success) {
                throw new Error(result.error || 'An error occurred');
            }

            // Display results
            if (result.count === 0) {
                resultsContainer.innerHTML = `
                    <div class="card">
                        <div class="card-body">
                            <div class="alert alert-info">
                                <strong>No results found.</strong> No data matches the selected date range.
                            </div>
                        </div>
                    </div>
                `;
            } else {
                let tableRows = '';
                result.data.forEach(row => {
                    const hasOffer = row.offer_id !== null;
                    const hasRequest = row.request_id !== null;
                    let rowClass = '';
                    let statusBadge = '';

                    if (hasOffer && !hasRequest) {
                        rowClass = 'table-warning';
                        statusBadge = '<span class="badge bg-warning">Excess Supply</span>';
                    } else if (!hasOffer && hasRequest) {
                        rowClass = 'table-danger';
                        statusBadge = '<span class="badge bg-danger">Unmet Demand</span>';
                    } else {
                        statusBadge = '<span class="badge bg-success">Matched</span>';
                    }

                    tableRows += `
                        <tr class="${rowClass}">
                            <td>${escapeHtml(row.zone)}</td>
                            <td>${row.ride_day}</td>
                            <td>${row.offer_id || '<em>None</em>'}</td>
                            <td>${row.request_id || '<em>None</em>'}</td>
                            <td>${statusBadge}</td>
                        </tr>
                    `;
                });

                resultsContainer.innerHTML = `
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">Results</h5>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-success">
                                Found <strong>${result.count}</strong> record(s).
                            </div>
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered">
                                    <thead>
                                        <tr>
                                            <th>Zone</th>
                                            <th>Ride Day</th>
                                            <th>Offer ID</th>
                                            <th>Request ID</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${tableRows}
                                    </tbody>
                                </table>
                            </div>
                            <div class="mt-3">
                                <small class="text-muted">
                                    <strong>Legend:</strong> 
                                    <span class="badge bg-warning">Excess Supply</span> = Offer without matching request, 
                                    <span class="badge bg-danger">Unmet Demand</span> = Request without matching offer,
                                    <span class="badge bg-success">Matched</span> = Both offer and request exist
                                </small>
                            </div>
                        </div>
                    </div>
                `;
            }
        } catch (error) {
            resultsContainer.innerHTML = `
                <div class="card">
                    <div class="card-body">
                        <div class="alert alert-danger">
                            <h5>Error</h5>
                            <p>${escapeHtml(error.message)}</p>
                        </div>
                    </div>
                </div>
            `;
        }
    });
});

function escapeHtml(text) {
    if (text == null) return '';
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}

