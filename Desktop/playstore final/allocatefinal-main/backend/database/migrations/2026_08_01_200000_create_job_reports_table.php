<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('job_post_id')->constrained('job_posts')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 100);          // short category
            $table->text('description')->nullable();  // free-text from seeker
            $table->enum('status', ['pending', 'reviewed', 'dismissed'])->default('pending');
            $table->text('admin_note')->nullable();
            $table->timestamps();
            $table->unique(['job_post_id', 'user_id']); // one report per user per job
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_reports');
    }
};
