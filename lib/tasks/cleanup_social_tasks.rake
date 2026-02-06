namespace :social_tasks do
  desc "Clean up and fix social tasks data"
  task cleanup: :environment do
    puts "Starting social tasks cleanup..."
    
    # Remove invalid tasks (empty names or URLs)
    invalid_tasks = SocialTask.where(name: ['', nil]).or(SocialTask.where(url: ['', nil]))
    puts "Found #{invalid_tasks.count} invalid tasks"
    
    invalid_tasks.destroy_all
    puts "Removed invalid tasks"
    
    # Ensure all remaining tasks have proper data
    SocialTask.all.each_with_index do |task, index|
      if task.name.blank? || task.url.blank? || task.description.blank?
        task.update!(
          name: "Social Media Campaign #{index + 1}",
          url: "https://example.com/campaign-#{index + 1}",
          description: "Engage with our content on social media. Like, share, or comment to earn rewards."
        )
        puts "Fixed task #{task.id}: #{task.name}"
      end
    end
    
    # Add sample images to tasks that don't have them
    SocialTask.all.each_with_index do |task, index|
      if task.image.blank?
        sample_images = [
          'https://images.unsplash.com/photo-1611944212129-29977ae1398c?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1611605698335-8b1569810432?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=200&h=200&fit=crop',
          'https://images.unsplash.com/photo-1563986768494-4dee2763ff3f?w=200&h=200&fit=crop'
        ]
        
        task.update!(image: sample_images[index % sample_images.length])
        puts "Added image to task #{task.id}"
      end
    end
    
    final_count = SocialTask.count
    puts "Cleanup completed! Final task count: #{final_count}"
    
    # Display final tasks
    puts "\nCurrent valid tasks:"
    SocialTask.all.each do |task|
      puts "ID: #{task.id}, Name: '#{task.name}', URL: '#{task.url}'"
    end
  end
end