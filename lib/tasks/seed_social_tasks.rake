namespace :social_tasks do
  desc "Seed social tasks with sample data"
  task seed_sample_data: :environment do
    # Update existing tasks
    tasks_data = [
      {
        id: 1,
        name: 'Like & Share Our Product Post',
        url: 'https://facebook.com/example',
        description: 'Like and share our latest product announcement on Facebook to help spread the word about our amazing new features.'
      },
      {
        id: 2,
        name: 'Instagram Story Feature',
        url: 'https://instagram.com/example',
        description: 'Create an Instagram story featuring our product and tag us to showcase how you use our service in your daily life.'
      },
      {
        id: 3,
        name: 'Twitter Engagement Campaign',
        url: 'https://twitter.com/example',
        description: 'Follow our account and retweet our latest announcement to help increase our reach and engagement on Twitter.'
      }
    ]

    tasks_data.each do |data|
      task = SocialTask.find(data[:id])
      task.update!(
        name: data[:name],
        url: data[:url],
        description: data[:description]
      )
      puts "Updated task #{task.id}: #{task.name}"
    end

    # Create additional sample tasks if needed
    while SocialTask.count < 5
      SocialTask.create!(
        name: "Sample Social Task #{SocialTask.count + 1}",
        url: "https://example.com/social-task-#{SocialTask.count + 1}",
        description: "Complete this social media task to earn rewards. Share, like, or engage with our content to help grow our community."
      )
      puts "Created new task: Sample Social Task #{SocialTask.count}"
    end

    puts "Social tasks seeding completed!"
    puts "Total tasks: #{SocialTask.count}"
  end
end