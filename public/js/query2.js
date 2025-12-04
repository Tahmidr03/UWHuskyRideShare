document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('query2Form');
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
            const response = await fetch('/api/query2', {
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
                                <strong>No results found.</strong> No drivers match the criteria.
                            </div>
                        </div>
                    </div>
                `;
            } else {
                let tableRows = '';
                result.drivers.forEach(driver => {
                    tableRows += `
                        <tr>
                            <td>${escapeHtml(driver.driver_name)}</td>
                            <td><span class="badge bg-success">${driver.avg_score}</span></td>
                        </tr>
                    `;
                });

                resultsContainer.innerHTML = `
                    <div class="card">
                        <div class="card-body">
                            <h5 class="card-title">Results</h5>
                            <div class="alert alert-success">
                                Found <strong>${result.count}</strong> top-rated driver(s).
                            </div>
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered">
                                    <thead class="table-dark">
                                        <tr>
                                            <th>Driver Name</th>
                                            <th>Average Rating</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${tableRows}
                                    </tbody>
                                </table>
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

