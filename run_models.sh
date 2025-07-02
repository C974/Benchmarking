#!/bin/bash

# Array of models to test
models=(
    "tiiuae/falcon-11B"
    "google/gemma-3-12b-it"
    "meta-llama/Meta-Llama-3-8B-Instruct"
    "QCRI/Fanar-1-9B-Instruct"

    
)

# Base command configuration
TASKS=("testtask" "testpalestine")
DEVICE="auto"
BATCH_SIZE=1
NUM_FEWSHOT=1

# Create output directory if it doesn't exist
mkdir -p benchmark_results

echo "Starting model benchmarking..."
echo "Models to test: ${#models[@]}"
echo "Tasks: ${TASKS[*]}"
echo "Device: $DEVICE"
echo "Batch size: $BATCH_SIZE"
echo "Few-shot examples: $NUM_FEWSHOT"
echo "=================================="

# Loop through each model
for i in "${!models[@]}"; do
    model="${models[$i]}"
    echo ""
    echo "[$((i+1))/${#models[@]}] Testing model: $model"
    echo "Time: $(date)"
    echo "----------------------------------"
    
    # Extract model name for output file (replace / with -)
    model_name=$(echo "$model" | sed 's/\//-/g')
    
    # Loop through each task
    for j in "${!TASKS[@]}"; do
        task="${TASKS[$j]}"
        echo ""
        echo "  Running task: $task"
        
        # Create log file for this model and task
        log_file="benchmark_results/log_${model_name}_${task}_$(date +%Y%m%d_%H%M%S).txt"
        
        # Run the evaluation
        echo "  Running evaluation for $model on task $task..."
        echo "  Log file: $log_file"
        
        lm-eval \
            --model hf \
            --model_args pretrained="$model" \
            --tasks "$task" \
            --device "$DEVICE" \
            --batch_size "$BATCH_SIZE" \
            --num_fewshot "$NUM_FEWSHOT" \
            2>&1 | tee "$log_file"
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "  ✓ Successfully completed evaluation for $model on task $task"
        else
            echo "  ✗ Failed to complete evaluation for $model on task $task"
            echo "  Check log file: $log_file"
        fi
        
        echo "  Finished task $task at $(date)"
        
        # Add a small delay between tasks (optional)
        if [ $((j+1)) -lt ${#TASKS[@]} ]; then
            echo "  Waiting 3 seconds before next task..."
            sleep 3
        fi
    done
    
    echo "Finished testing $model at $(date)"
    echo "----------------------------------"
    
    # Add a small delay between models (optional)
    if [ $((i+1)) -lt ${#models[@]} ]; then
        echo "Waiting 10 seconds before next model..."
        sleep 10
    fi
done

echo ""
echo "=================================="
echo "All model evaluations completed!"
echo "Check the benchmark_results/ directory for detailed logs"
echo "Finished at: $(date)"
