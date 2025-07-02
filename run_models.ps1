# PowerShell script to run lm-eval with multiple models
# Array of models to test
$models = @(
    "tiiuae/falcon-11B",
    "google/gemma-3-12b-it",
    "meta-llama/Meta-Llama-3-8B-Instruct"
)

# Base command configuration
$TASKS = @("testtask", "testpalestine")
$DEVICE = "auto"
$BATCH_SIZE = 1
$NUM_FEWSHOT = 1

# Create output directory if it doesn't exist
if (!(Test-Path "benchmark_results")) {
    New-Item -ItemType Directory -Path "benchmark_results"
}

Write-Host "Starting model benchmarking..." -ForegroundColor Green
Write-Host "Models to test: $($models.Count)"
Write-Host "Tasks: $($TASKS -join ', ')"
Write-Host "Device: $DEVICE"
Write-Host "Batch size: $BATCH_SIZE"
Write-Host "Few-shot examples: $NUM_FEWSHOT"
Write-Host "==================================" -ForegroundColor Yellow

# Loop through each model
for ($i = 0; $i -lt $models.Count; $i++) {
    $model = $models[$i]
    Write-Host ""
    Write-Host "[$($i+1)/$($models.Count)] Testing model: $model" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date)"
    Write-Host "----------------------------------"
    
    # Extract model name for output file (replace / with -)
    $model_name = $model -replace "/", "-"
    
    # Loop through each task
    for ($j = 0; $j -lt $TASKS.Count; $j++) {
        $task = $TASKS[$j]
        Write-Host ""
        Write-Host "  Running task: $task" -ForegroundColor Magenta
        
        # Create log file for this model and task
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $log_file = "benchmark_results/log_${model_name}_${task}_${timestamp}.txt"
        
        # Run the evaluation
        Write-Host "  Running evaluation for $model on task $task..." -ForegroundColor Yellow
        Write-Host "  Log file: $log_file"
        
        try {
            $command = "lm-eval --model hf --model_args pretrained=`"$model`" --tasks `"$task`" --device `"$DEVICE`" --batch_size $BATCH_SIZE --num_fewshot $NUM_FEWSHOT"
            
            # Execute the command and capture output
            Invoke-Expression $command 2>&1 | Tee-Object -FilePath $log_file
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Successfully completed evaluation for $model on task $task" -ForegroundColor Green
            }
            else {
                Write-Host "  ✗ Failed to complete evaluation for $model on task $task" -ForegroundColor Red
                Write-Host "  Check log file: $log_file"
            }
        }
        catch {
            Write-Host "  ✗ Error running evaluation for $model on task $task" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)"
            $_.Exception.Message | Out-File -FilePath $log_file -Append
        }
        
        Write-Host "  Finished task $task at $(Get-Date)"
        
        # Add a small delay between tasks (optional)
        if (($j + 1) -lt $TASKS.Count) {
            Write-Host "  Waiting 3 seconds before next task..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
    }
    
    Write-Host "Finished testing $model at $(Get-Date)"
    Write-Host "----------------------------------"
    
    # Add a small delay between models (optional)
    if (($i + 1) -lt $models.Count) {
        Write-Host "Waiting 10 seconds before next model..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Yellow
Write-Host "All model evaluations completed!" -ForegroundColor Green
Write-Host "Check the benchmark_results/ directory for detailed logs"
Write-Host "Finished at: $(Get-Date)" -ForegroundColor Green
