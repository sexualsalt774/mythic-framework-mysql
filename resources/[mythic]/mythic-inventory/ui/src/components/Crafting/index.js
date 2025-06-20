import React, { useEffect, useState } from 'react';
import {
	TextField,
	InputAdornment,
	IconButton,
	Alert,
	CircularProgress,
	Button,
} from '@mui/material';
import { makeStyles } from '@mui/styles';
import { useSelector, useDispatch } from 'react-redux';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import Recipe from './recipe';
import { getItemImage } from '../Inventory/item';

import { useTheme } from '@mui/material/styles';

const useStyles = makeStyles((styles) => ({
	loadingScreen: {
		position: 'absolute',
		width: 'fit-content',
		height: 'fit-content',
		top: 0,
		bottom: 0,
		right: 0,
		left: 0,
		margin: 'auto',
		textAlign: 'center',
		'& span': {
			display: 'block',
			marginTop: 15,
			color: "#fff",
		},
	},
	wrapper: {
		display: 'flex',
		justifyContent: 'space-between',
		alignItems: 'center',
		userSelect: 'none',
		'-webkit-user-select': 'none',
		width: '100%',
		height: '100%',
		paddingTop: "11%",
		paddingBottom: "11%",
		paddingRight: "15%",
		paddingLeft: "15%",
	},
	wrapperContainer: {
		display: 'flex',
		justifyContent: 'center',
		alignItems: 'center',
		flexDirection: "column",
		userSelect: 'none',
		'-webkit-user-select': 'none',
		width: "100%",
		height: "100%",
	},
	topContainer: {
		flex: '0 0 15%',
		width: "100%",
		display: 'flex',
		justifyContent: 'flex-start',
		alignItems: 'center',
	},
	topLeftContainer: {
		width: "15%",
		background: 'rgba(18, 18, 28, 0.7)',
		//backdropFilter: "blur(5px)",
		height: "60%",
		borderRadius: 8,
		display: "flex",
		justifyContent: "center",
		textAlign: "center",
		alignItems: "center",
		fontWeight: 600,
		fontSize: 18,
		boxShadow: "0 4px 15px rgba(0, 0, 0, 0.15)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
	},
	bottomContainer: {
		flex: '0 0 85%',
		width: "100%",
		display: "flex",
		justifyContent: "space-between",
		alignItems: "center",
		overflow: "hidden",
	},
	leftContainer: {
		flex: '0 0 49%',
		height: "100%",
		overflow: "hidden",
		display: "flex",
		justifyContent: "center",
		alignItems: "center",
	},
	leftContainerTop: {
		width: "100%",
		height: "10%",
		display: "flex",
		justifyContent: "space-between",
		flexDirection: "row",
		alignItems: "center",
		padding: "0 10px",
		borderRadius: 8,
		boxShadow: 'inset 0 0 4vh rgba(13, 13, 13, 0.8)',
		overflow: "hidden",
		marginBottom: 16,
	},
	rightContainer: {
		flex: '0 0 49%',
		height: "100%",
	},
	noRecipes: {
		fontWeight: 700,
		fontSize: 18,
		padding: 24,
		textAlign: 'center',
		color: "#fff",
	},
	gridContainer: {
		display: 'grid',
		gridAutoRows: 'max-content',
		gridTemplateColumns: 'repeat(5, 17%)',
		justifyContent: "space-between",
		width: "100%",
		maxWidth: "100%",
		overflowX: "hidden",
		gap: 16,
		overflowY: "auto",
		height: "92%",
		'&::-webkit-scrollbar': {
			width: 6,
		},
		'&::-webkit-scrollbar-thumb': {
			background: "rgba(255, 255, 255, 0.1)",
			borderRadius: 3,
			transition: "background ease-in 0.15s",
		},
		'&::-webkit-scrollbar-thumb:hover': {
			background: "rgba(255, 255, 255, 0.2)",
		},
		'&::-webkit-scrollbar-track': {
			background: "transparent",
		},
	},
	gridItem: {
		display: "flex",
		justifyContent: "center",
		alignItems: "center",
		width: "auto",
		height: "100%",
		aspectRatio: '1 / 1',
		backgroundColor: "rgba(18, 18, 28, 0.7)",
		borderRadius: 8,
		padding: 0,
		margin: 0,
		flexDirection: "column",
		overflow: "hidden",
		border: "1px solid rgba(255, 255, 255, 0.05)",
		transition: "all 0.2s ease",
		"&:hover": {
			transform: "translateY(-2px)",
			boxShadow: "0 6px 20px rgba(0, 0, 0, 0.25)",
			backgroundColor: "rgba(28, 28, 38, 0.7)",
		}
	},
	mainImage: {
		height: "auto",
		width: '50%',
		objectFit: 'contain', 
	},
	gridText: {
		fontSize: 12,
		fontWeight: 600,
		textTransform: "none",
		marginTop: 8,
	},
	searchIcon: {
		color: "rgba(255, 255, 255, 0.5)",
		marginRight: 8,
		fontSize: 16,
	},
	searchField: {
		'& .MuiInputBase-root': {
			color: "#fff",
			fontSize: 14,
		},
		'& .MuiInputBase-input': {
			padding: "6px 0",
		},
	},
}));

const Crafting = () => {
	const classes = useStyles();
	const itemsLoaded = useSelector((state) => state.inventory.itemsLoaded);
	const items = useSelector((state) => state.inventory.items);
	const cooldowns =
		useSelector((state) => state.crafting.cooldowns) || {};
	const recipes = useSelector((state) => state.crafting.recipes);
	const crafting = useSelector((state) => state.crafting.crafting);
	const theme = useTheme();
	const [filtered, setFiltered] = useState(recipes);
	const [search, setSearch] = useState('');

	const benchName = useSelector((state) => state.crafting.benchName);

	const currentCraft = useSelector((state) => state.crafting.currentCraft);
	
	const dispatch = useDispatch();

	const setCurrentCraft = (number) => {
		//console.log("Setting Current Craft", number);
		dispatch({
			type: 'CURRENT_CRAFT',
			payload: { 
			  currentCraft: number
			},
		});
	};

	const getRarityColor = (rarity) => {
		switch (rarity) {
		  case 1:
			return theme.palette.rarities.rare1;
		  case 2:
			return theme.palette.rarities.rare2;
		  case 3:
			return theme.palette.rarities.rare3;
		  case 4:
			return theme.palette.rarities.rare4;
		  case 5:
			return theme.palette.rarities.rare5;
		  default:
			return theme.palette.rarities.rare1;
		}
	};

	useEffect(() => {
		setFiltered(
			Object.keys(recipes)
				.filter((r) =>
					items[recipes[r].result.name]?.label
						.toLowerCase()
						.includes(search.toLowerCase())
				)
				.map((k) => recipes[k])
		);
	}, [search, recipes, items]);

	const onChange = (e) => {
		setSearch(e.target.value);
	};

	if (!itemsLoaded || Object.keys(items).length === 0) {
		return (
			<div className={classes.loadingScreen}>
				<CircularProgress size={36} style={{ margin: 'auto' }} />
				<span>Loading Inventory Items</span>
				<Alert
					style={{ marginTop: 20 }}
					variant="outlined"
					severity="info"
				>
					If you see this for a long period of time, there may be an
					issue. Try restarting your FiveM.
				</Alert>
			</div>
		);
	} else {
		return (
			<div className={classes.wrapper}>
				<div className={classes.wrapperContainer}>
					<div className={classes.topContainer}>
						{benchName != 'none' &&
							<div className={classes.topLeftContainer}>
								{benchName}
							</div>
						}
					</div>
					<div className={classes.bottomContainer}>
						<div className={classes.leftContainer}>
							{/* <div className={classes.leftContainerTop}>
								<FontAwesomeIcon 
									icon={['fas', 'search']} 
									style={{ 
										color:"rgba(43, 168, 237, 0.7)",
										marginRight: "1vh",
										fontSize: "1.5vh", 
									}}
								/>

								<TextField
									fullWidth
									placeholder="Search" 
									variant="standard" 
									value={search}
									onChange={onChange}
									disabled={!Boolean(crafting)}
									InputProps={{
										disableUnderline: true, 
										endAdornment: (
										<InputAdornment position="end">
											<IconButton onClick={() => setSearch('')} edge="end">
												{Boolean(search) && (
													<FontAwesomeIcon 
														icon={['fas', 'times']}
														style={{
															fontSize: "1.5vh", 
														}}
													/>
												)}
											</IconButton>
										</InputAdornment>
										),
										style: {
											border: 'none',
											backgroundColor: 'transparent',
											fontSize: "1.5vh",
										},
									}}
									inputProps={{
										style: {
											padding: 0, 
										},
									}}
								/>
							</div>  */}
							{Boolean(filtered) && filtered.length > 0 && (
								<div className={classes.gridContainer} >
									{filtered.map((recipe, index) => (
										<Button		
											key={`${recipe.name}-${index}`}
											index={index}
											className={classes.gridItem}	
											onClick={() => setCurrentCraft(index)}
											style={{
												boxShadow: `inset 0 0 2vh ${getRarityColor(items[recipe.result.name]?.rarity)}`, 
												color: "white",
											}}
										>
											<img 
												className={classes.mainImage}
												src={getItemImage(
													recipe.result,
													items[recipe.result.name],
												)}
													//onMouseEnter={resultTPOpen}
													//onMouseLeave={resultTPClose}
											/>

											<div className={classes.gridText} >
												{items[recipe.result.name]?.label}
											</div>
										</Button>
									))}
								</div>
							// ):(
							// 	<div className={classes.noRecipes}>No Crafting Blueprints</div>
							)}
						</div>

						{Boolean(filtered) && filtered.length > 0 && currentCraft !== null && (
							<div className={classes.rightContainer}>
								{filtered[currentCraft] && (
									<Recipe
										key={`${filtered[currentCraft].name}-${currentCraft}`}
										index={currentCraft}
										recipe={filtered[currentCraft]}
										cooldown={cooldowns[filtered[currentCraft].id]}
									/>
								)}
							</div>
						)}
						
					</div>
				</div>
			</div>
		);
	}
};

export default Crafting;
