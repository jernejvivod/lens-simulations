folder = fileparts(which(mfilename)); 
addpath(genpath(folder));

% Authors Kim Ana Badovinac, Katja Logar, Jernej Vivod
% // First Screen Configuration ///////////////////////////////////

printf("The light source is fixed at point (0, 0, 0).\n");
printf("The first screen is at a fixed distance of 1 from the light source.\n");
printf("The default length of the side of the first screen is 1 and can be scaled.\n");
printf("\n");

scaling_factor = input("Enter first screen scaling factor: ");
% Define first screen spanning vectors.
v1 = [0; 0; -1];
v2 = [0; 1; 0];

% Compute screen centering values (Used to center screen when scaling is applied).
delta_scaling1 = ((norm(v1) * scaling_factor) - norm(v1)) / 2;
delta_scaling2 = ((norm(v2) * scaling_factor) - norm(v2)) / 2;

% Compute coordinates of the left upper corner of the first screen
screen_lu_coordinates = [1; -0.5 - delta_scaling2; 1 + delta_scaling1];

% Apply scaling factor to first screen spanning vectors.
v1 *= scaling_factor;
v2 *= scaling_factor;

% //////////////////////////////////////////////////////////////////

% // Second Screen Configuration ///////////////////////////////////
printf("\nThe default length of a side of the second screen is 2 and can be scaled.\n");
printf("\n");
scaling_factor = input("Enter second screen scaling factor: ");

% Define second screen spanning vectors.
vf1 = [0; 0; -2];
vf2 = [0; 2; 0];

% Compute screen centering values (Used to center screen when scaling is applied).
delta_scaling1 = ((norm(vf1) * scaling_factor) - norm(vf1)) / 2;
delta_scaling2 = ((norm(vf2) * scaling_factor) - norm(vf2)) / 2;

% Apply scaling factor to second screen spanning vectors.
vf1 *= scaling_factor;
vf2 *= scaling_factor;

% Parse distance between screens.
screen_distance = input("\nEnter distance between screens: ");

% Compute coordinates of the left upper corner of the first screen
finalScreen_lu_coordinates = [1 + screen_distance; -1 - delta_scaling2; 2 + delta_scaling1*2];

% //////////////////////////////////////////////////////////////////

% Set light source coordinates.
light_source_coordinates = [0; 0; 0];

% Load image.
image_selection = input("\nUse random image? y/n ", 's');
if strcmp(image_selection, 'y')
	cd('test_images');	
	load('CatDog.mat');
	testing_image = reshape(CatDog(ceil(rand()* size(CatDog)(1)), :), 64, 64);
	cd('..');
else
	%load cat_picture.m;
	%testing_image = cat_picture;
	testing_image = rand(8, 8);
endif

% Get matrix of coordinates of pixels on first screen.
C = get_pixel_coordinates(screen_lu_coordinates, v1, v2, testing_image);

% Construct line equations representing rays going through light source and pixle on first screen.
F = make_line_functions(C, light_source_coordinates);

% LENSING APPLICATION ####################################################################################

% Prompt for lens shape (let user choose from set of predefined equations)
% Prompt for n1 and n2. Let users choose from list of materials or enter custom values.
printf("\nChose the medium surrounding the lens:\n");
printf("1 --- Vacuum\n2 --- Air\n3 --- Glass\n4 --- Water\n5 --- Ice\n6 --- Diamond\n");

while(1)
	n = input("");
	switch n
		case 1	
			lens.n1 = 1;
			break;
		case 2
			lens.n1 = 1.000277;
			break;
		case 3
			lens.n1 = 1.458; 
			break;
		case 4
			lens.n1 = 1.330;
			break;
		case 5
			lens.n1 = 1.31;
			break;
		case 6
			lens.n1 = 2.417;
			break;
		otherwise
			printf("Please enter a valid option.\n");
		endswitch
endwhile

printf("\nChose material the lens is made of:\n");
printf("1 --- Vacuum\n2 --- Air\n3 --- Glass\n4 --- Water\n5 --- Ice\n6 --- Diamond\n");

while(1)
	n = input("");
	switch n
		case 1	
			lens.n2 = 1;
			break;
		case 2
			lens.n2 = 1.000277;
			break;
		case 3
			lens.n2 = 1.458; 
			break;
		case 4
			lens.n2 = 1.330;
			break;
		case 5
			lens.n2 = 1.31;
			break;
		case 6
			lens.n2 = 2.417;
			break;
		otherwise
			printf("Please enter a valid option.\n");
	endswitch
endwhile

% initialize lens
lens.equation = @(x, y, z) ((x - 2.5).^2) + y.^2 + (z - 0.5).^2 - 1;
%lens.n1 = 1.00029; % air
%lens.n2 = 1.52; % glass

visualize = input("\nVisualize the system of screens and mirrors? (WARNING: only works in MATLAB) y/n ", 's');
visualize_bin = 0;
if strcmp(visualize, 'y')
	visualize_bin = 1;
	im3 = figure('Name','Lens and Screens Configuration','NumberTitle','off');	
endif

% apply lensing to rays
% THE LAST PARAMETER TELLS THE FUNCTION IF WE WANT TO PLOT CONFIGURATION VISUALIZATIONS AS WELL.
F_trans = apply_lensing_all(F, lens, visualize_bin);

% ########################################################################################################

% Get instersection coordinates of rays with second screen.
% The indices matrix stores the index of the pixel whose ray intersected.
[intersections, indices] = get_intersections_finalScreen(F_trans, finalScreen_lu_coordinates, vf1, vf2);

% Compute indices of pixels that were intersected by each ray.
new_indices = get_intersection_indices(intersections, finalScreen_lu_coordinates, vf1, vf2, size(testing_image));

% Get transformed image.
transformed_image = get_transfromed_image(testing_image, indices, new_indices);

% Show original image
im1 = figure('Name','Original Image','NumberTitle','off');
im2 = figure('Name','Transformed Image','NumberTitle','off');

figure(im1);
imagesc(testing_image); colormap gray;
title("Original Image");

% Display transformed image.
figure(im2);
h2 = imagesc(transformed_image); colormap gray;
title("Transformed Image");


if visualize_bin
	figure(im3);
	plot_finalScreen_frame(finalScreen_lu_coordinates, vf1, vf2);
	grid on;
	hold on;
	plot_3d_vector(light_source_coordinates, 'r*');
	plot_screen(C);
	plot_ellipsoid([2.5; 0; 0.5], 1, [1; 1; 1]);
	%plot_rays(F);
	view(0, 90);
	axis equal
endif